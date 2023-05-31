<template>

    <q-chat-message
    :size="response ? '4' : '8'"
    :name="chatResponse.fields.author ? ((''+chatResponse.fields.author).substr(0,6)+'...'+(''+chatResponse.fields.author).substr(-4)) : ((''+chatResponse.localProperties.author).substr(0,6)+'...'+(''+chatResponse.localProperties.author).substr(-4))"
    :class="computedClasses"
    sent
    >
        <div>
            {{ messageText }}
            <span class="messageMetaBlock">


                <q-btn round color="primary" size="sm" flat icon="reply" @click="reply" />
                <q-btn round color="primary" size="sm" flat icon="open_in_new" @click="openOnExplorer" />
            </span>
        </div>
    </q-chat-message>

    <template v-for="(response) in responses" v-bind:key="response.address">
        <SuiChatMessage :suiMaster="suiMaster" :chatResponse="response" response  @reply="onSetReply" />
    </template>

</template>

<style lang="css">
    .messageMetaBlock {
        display: block;
        text-align: right;
    }


    .chatMessageBackColor1 .q-message-text {
        background-color: #ed9482;
    }
    .chatMessageBackColor1 .q-message-text--sent:last-child:before {
        border-bottom-color: #ed9482;
    }
    .chatMessageBackColor2 .q-message-text {
        background-color: #a8db92;
    }
    .chatMessageBackColor2 .q-message-text--sent:last-child:before {
        border-bottom-color: #a8db92;
    }
    .chatMessageBackColor3 .q-message-text {
        background-color: #efd289;
    }
    .chatMessageBackColor3 .q-message-text--sent:last-child:before {
        border-bottom-color: #efd289;
    }
    /* .chatMessageBackColor4 .q-message-text {
        background-color: #8fbfe9;
    }
    .chatMessageBackColor4 .q-message-text--sent:last-child:before {
        border-bottom-color: #8fbfe9;
    }
    .chatMessageBackColor5 .q-message-text {
        background-color: #9992e4;
    }
    .chatMessageBackColor5 .q-message-text--sent:last-child:before {
        border-bottom-color: #9992e4;
    } */
    .chatMessageBackColor4 .q-message-text {
        background-color: #ffa9c3;
    }
    .chatMessageBackColor4 .q-message-text--sent:last-child:before {
        border-bottom-color: #ffa9c3;
    }
    .chatMessageBackColor5 .q-message-text {
        background-color: #8eccdb;
    }
    .chatMessageBackColor5 .q-message-text--sent:last-child:before {
        border-bottom-color: #8eccdb;
    }
    .chatMessageBackColor6 .q-message-text {
        background-color: #f7b37c;
    }
    .chatMessageBackColor6 .q-message-text--sent:last-child:before {
        border-bottom-color: #f7b37c;
    }
</style>

<script>

export default {
	name: 'SuiChatMessage',
	props: {
        suiMaster: {
            type: Object,
            default: null,
        },
        chatResponse: {
            type: Object,
            default: null,
        },
        response: {
            type: Boolean,
            default: false,
        },
	},
	data() {
		return {
			isLoading: false,
            responses: [],
            responsesDict: {},
		}
	},
    emits: ['reply'],
	watch: {
	},
	computed: {
        messageText() {
            if (this.chatResponse.fields.text) {
                return new TextDecoder().decode(new Uint8Array(this.chatResponse.fields.text));
            } else {
                return this.chatResponse.localProperties.text;
            }
        },
        countOfResponses: function() {
            if (!this.chatResponse.localProperties || !this.chatResponse.localProperties.responses) {
                return 0;
            }

            return this.chatResponse.localProperties.responses.length;
        },
        computedClasses: function() {
            const classes = {};
            classes['chatMessageBackColor'+this.getColorN()] = true;
            return classes;
        }
	},
	components: {
	},
	methods: {
        refreshResponses() {
            for (const key in this.chatResponse.localProperties.responses) {
                if (!this.responsesDict[this.chatResponse.localProperties.responses[key].address]) {
                    this.responses.unshift(this.chatResponse.localProperties.responses[key]);
                    this.responsesDict[this.chatResponse.localProperties.responses[key].address] = this.chatResponse.localProperties.responses[key];
                }
            }
        },
        onSetReply(responseChatResponse) {
            this.$emit('reply', responseChatResponse);
        },  
        reply() {
            this.$emit('reply', this.chatResponse);
        },
        openOnExplorer() {
            let network = 'mainnet';
            try {
                network = (''+this.chatResponse._suiMaster.signer.getCurrentChain()).split('sui:').join('');
            } catch (e) {
                console.error(e);
            }

            window.open('https://suiexplorer.com/object/'+this.chatResponse.address+'?network='+network, '_blank');
        },  
        getColorN() {
            const author = this.chatResponse.fields.author ? this.chatResponse.fields.author : this.chatResponse.localProperties.author;
            const charCode = Math.random() * 1000 + author.charCodeAt(3) + author.charCodeAt(4);
            return (Math.ceil(charCode) % 6) + 1;
        }
	},
	beforeMount: function() {
	},
	mounted: async function() {
        this.refreshResponses();
	},
}
</script>
