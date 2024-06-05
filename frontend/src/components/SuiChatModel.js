class SuiChatModel extends EventTarget {
    constructor(params = {}) {
        super();

        this.suiMaster = params.suiMaster;
        if (!this.suiMaster) {
            throw new Error('suiMaster is required');
        }

        this.isInitialized = false;

        this.pkg = null,
        this.objectStorage = null,
        this.topResponses = [];
        this.topMessages = {};

        this.packagesOnChains = {
            'sui:devnet': '0x81ef3f54c1f41149f7be63ab6d54b25ab73a2db1402734cbe016710acf17887e',
            'sui:testnet': '0x7179bb4dd2b490a218e5bb68f72e05139f6aec7d31031d0f05343aefd2c33ebe',
            'sui:mainnet': '0xb91fa08fde91c1999a98fdc5b8ed53b08600167701f1a4308101b19c33262f2a',
        };
    }

    static __instances = {};
    static bySuiMaster(suiMaster) {
        const suiMasterInstanceN = suiMaster.instanceN;
        if (SuiChatModel.__instances[suiMasterInstanceN]) {
            return SuiChatModel.__instances[suiMasterInstanceN];
        } else {
            const suiChatModel = new SuiChatModel({
                suiMaster: suiMaster,
            });
            SuiChatModel.__instances[suiMasterInstanceN] = suiChatModel;

            setTimeout(()=>{
                suiChatModel.initialize(); // no waiting
            }, 50);

            return suiChatModel;
        }
    }

    async sendMessage(params = {}) {
        const messageText = params.text;
        const replyToTopMessageId = params.replyToTopMessageId;

        const chatShopObjectId = this.pkg.localProperties.chatShopObjectId;

        const messageTextAsBytes = [].slice.call(new TextEncoder().encode(messageText)); // regular array with utf data

        let method = 'post';
        let moveParams = [chatShopObjectId, this.pkg.arg('vector<u8>', messageTextAsBytes), this.pkg.arg('string', 'metadata')];
        if (replyToTopMessageId) {
            method = 'reply';
            moveParams = [replyToTopMessageId, this.pkg.arg('vector<u8>', messageTextAsBytes), this.pkg.arg('string', 'metadata')];
        }

        let secondUserCallResult = await this.pkg.moveCall('chat', method, moveParams);

        if (secondUserCallResult && secondUserCallResult.created) {
            for (const created of secondUserCallResult.created) {
                if (created.typeName == 'ChatResponse') {
                    created.localProperties.text = messageText; // we may not immediately get fields from blockchain
                    created.localProperties.author = this.suiMaster.address; // we may not immediately get fields from blockchain
                    if (!created.localProperties.responses) {
                        created.localProperties.responses = [];
                        created.localProperties.responsesDict = {};
                    }

                    let top_message_id = null;
                    if (replyToTopMessageId) {
                        top_message_id = replyToTopMessageId;
                    } else {
                        // posted? Find in created
                        for (const anotherCreated of secondUserCallResult.created) {
                            if (anotherCreated.typeName == 'ChatTopMessage') {
                                top_message_id = anotherCreated.address;
                            }
                        }
                    }

                    if (top_message_id) {
                        created.localProperties.chat_top_message_id = top_message_id;

                        if (!replyToTopMessageId) {
                            // posted top level
                            this.topResponses.unshift(created);
                            this.topMessages[top_message_id] = created;

                            this.emit('top', {
                                chatResponse: created,
                                chat_top_message_id: top_message_id,
                            });
                        } else {
                            this.topMessages[top_message_id].localProperties.responses.unshift(created);
                            this.topMessages[top_message_id].localProperties.responsesDict[created.address] = created;

                            this.emit('response', {
                                chatResponse: created,
                                chat_top_message_id: top_message_id,
                                firstChatResponseMessageId: this.topMessages[top_message_id].address,
                            });
                            // this.$refs['topChatResponse'+this.topMessages[top_message_id].address][0].refreshResponses();
                        }
                    }

                }
            }
        }

    }

    async initialize() {
        if (this.isInitialized) {
            return true;
        }

        console.error('this.suiMaster', this.suiMaster);
        const currentChain = this.suiMaster.signer.getCurrentChain();
        const packageId = this.packagesOnChains[currentChain];

        if (!packageId) {
            this.isInitialized = true;
            this.emit('clear', {supported: false, currentChain: currentChain});
            return false;
        } else {
            this.emit('clear', {supported: true});
        }


        const pkg = this.suiMaster.package({
            id: packageId,
        });

        try {
            let chatShopObjectId = null;
            if (pkg.localProperties.chatShopObjectId) {
                console.error('already here', pkg.localProperties.chatShopObjectId);
    
                chatShopObjectId = pkg.localProperties.chatShopObjectId;
            } else {
                const createdEventsResponse = await pkg.fetchEvents('chat', {eventTypeName: 'ChatShopCreated', order: 'ascending'});
                chatShopObjectId = createdEventsResponse.data[0].parsedJson.id;
    
                pkg.localProperties.chatShopObjectId = chatShopObjectId;
                console.error('got here', pkg.localProperties.chatShopObjectId);
            }
    
            this.pkg = pkg;
            this.objectStorage = pkg.modules.chat.objectStorage;
            this.isInitialized = true;
    
            await this.loadTopMessages();
        } catch (e) {
            console.error(e);
        }
    }

    async loadTopMessages() {
        const createdEventsResponse = await this.pkg.fetchEvents('chat', {eventTypeName: 'ChatResponseCreated', order: 'descending'});
        // console.log('eve', createdEventsResponse.data);

        for (const ev of createdEventsResponse.data) {
            if (ev.parsedJson && ev.parsedJson.id) {
                this.pkg.modules.chat.pushObject(ev.parsedJson.id);
            }
            if (ev.parsedJson && ev.parsedJson.top_message_id) {
                this.pkg.modules.chat.pushObject(ev.parsedJson.top_message_id);
            }
        }

        const topMessagesEvents = []; // store to emit in reverse order

        await this.pkg.modules.chat.fetchObjects();
        for (const ev of createdEventsResponse.data) {
            if (ev.parsedJson && ev.parsedJson.id && (ev.parsedJson.seq_n === 0 || ev.parsedJson.seq_n === '0')) {
                const top_message_id = ev.parsedJson.top_message_id;
                if (!this.topMessages[top_message_id]) {
                    this.topMessages[top_message_id] = this.objectStorage.byAddress(ev.parsedJson.id);
                    this.topMessages[top_message_id].localProperties.responses = [];
                    this.topMessages[top_message_id].localProperties.responsesDict = {};

                    this.topResponses.unshift(this.objectStorage.byAddress(ev.parsedJson.id));

                    topMessagesEvents.push({
                        chatResponse: this.objectStorage.byAddress(ev.parsedJson.id),
                        chat_top_message_id: top_message_id,
                    });

                    // this.emit('top', {
                    //         chatResponse: this.objectStorage.byAddress(ev.parsedJson.id),
                    //         chat_top_message_id: top_message_id,
                    //     });
                }
                // console.log('top response', this.objectStorage.byAddress(ev.parsedJson.id));
            }
        }

        // responses
        for (const ev of createdEventsResponse.data) {
            if (ev.parsedJson && ev.parsedJson.id && (ev.parsedJson.seq_n !== 0 && ev.parsedJson.seq_n !== '0')) {
                const top_message_id = ev.parsedJson.top_message_id;
                const chatResponse = this.objectStorage.byAddress(ev.parsedJson.id);
                if (this.topMessages[top_message_id] && chatResponse) {
                    // console.error('chatresponse', chatResponse);
                    if (!this.topMessages[top_message_id].localProperties.responsesDict[chatResponse.address]) {
                        this.topMessages[top_message_id].localProperties.responsesDict[chatResponse.address] = chatResponse;
                        this.topMessages[top_message_id].localProperties.responses.unshift(chatResponse);

                        // this.emit('response', {
                        //     chatResponse: chatResponse,
                        //     chat_top_message_id: top_message_id,
                        // });
                    }
                }
            }
        }

        const reversedTopMessagesEvents = topMessagesEvents.reverse();
        for (const event of reversedTopMessagesEvents) {
            this.emit('top', event);
        }
    }


	emit(eventType, data) {
		try {
			this.dispatchEvent(new CustomEvent(eventType, { detail: data }));
		} catch (e) {
			console.error(e);
		}
	}
}

module.exports = SuiChatModel;