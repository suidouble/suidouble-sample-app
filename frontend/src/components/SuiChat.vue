<template>

	<div class="q-pa-md">

    <q-input outlined bottom-slots v-model="sendText" label="Send" counter maxlength="256" :disable="!canSend">
    <template v-slot:hint>
        <span v-if="replyToAuthor" style="line-height: 25px;">
            Reply to {{ replyToAuthor }}
            <q-btn round color="red" size="xs" flat icon="close" @click="flushReply" />
        </span>
        <span v-if="!replyToAuthor" style="line-height: 25px;">Text message</span>
    </template>

    <template v-slot:after>
        <q-btn color="primary" round dense flat :icon="replyToAuthor ? 'reply' : 'send'" :disable="!canSend" @click="sendMessage" />
    </template>
    </q-input>

    <q-banner class="bg-primary text-white q-mt-lg" v-if="isNotSupported">
        Unfortunately, chain {{ notSupportedChainName }} is not supported. Try to switch to different one (maybe devnet?) in your wallet.
    </q-banner>
    <q-banner class="bg-primary text-white q-mt-lg relative-position" v-if="!isNotSupported && isLoading">
      <q-inner-loading showing>
        <q-spinner-gears size="20px" color="primary" />
      </q-inner-loading>
    </q-banner>

    <div class="q-pt-md q-pr-sm">
        <template v-for="(topChatResponse) in topResponses" v-bind:key="topChatResponse.address">
            <SuiChatMessage :suiMaster="suiMaster" :chatResponse="topChatResponse" @reply="onSetReply" :ref="'topChatResponse' + topChatResponse.address" />
        </template>
    </div>

    </div>

</template>

<style lang="css">
    .messageMetaBlock {
        display: block;
        text-align: right;
    }
</style>

<script>
import SuiChatMessage from './SuiChatMessage.vue';
import SuiChatModel from './SuiChatModel.js';

export default {
	name: 'SuiChat',
	props: {
        suiMaster: {
            type: Object,
            default: null,
        }
	},
	data() {
		return {
			isLoading: false,
			isInitialized: false,
			hasError: false,

            isNotSupported: false,
            notSupportedChainName: null,

            canSend: false,
            isSending: false,
            sendText: '',

            replyToAuthor: null,
            replyToTopMessageId: null,

            suiChatModel: null,
            topResponses: [],
		}
	},
	watch: {
        suiMaster: function() {
            this.initChatModel();
        }
	},
	computed: {
	},
	components: {
        SuiChatMessage,
	},
	methods: {
        initChatModel() {
            if (this.suiMaster) {
                if (this.suiChatModel) {
                    this.suiChatModel.removeEventListener('top', this.onTopMessage);
                    this.suiChatModel.removeEventListener('response', this.onResponse);
                    this.suiChatModel.removeEventListener('clear', this.onClear);
                }
                
                this.suiChatModel = SuiChatModel.bySuiMaster(this.suiMaster);
                this.suiChatModel.addEventListener('top', this.onTopMessage);
                this.suiChatModel.addEventListener('response', this.onResponse);
                this.suiChatModel.addEventListener('clear', this.onClear);
            }
        },
        onClear(ev) {
            const isSupported = ev.detail.supported;
            const currentChain = ev.detail.currentChain;

            this.notSupportedChainName = currentChain;
            this.isNotSupported = !isSupported;
            this.isLoading = true;
            this.topResponses = [];
        },
        onTopMessage(ev) {
            const chatResponse = ev.detail.chatResponse;
            this.isLoading = false;
            this.topResponses.unshift(chatResponse);
            // console.error(ev, this);
        },
        onResponse(ev) {
            const firstChatResponseMessageId = ev.detail.firstChatResponseMessageId;

            this.$refs['topChatResponse'+firstChatResponseMessageId][0].refreshResponses();
        },
        async sendMessage() {
            this.isSending = true;

            await this.suiChatModel.sendMessage({
                text: this.sendText,
                replyToTopMessageId: this.replyToTopMessageId,
            });

            this.sendText = '';
            this.isSending = false;
            this.flushReply();
        },
        onSetReply(chatResponse) {
            this.replyToTopMessageId = chatResponse.fields.chat_top_message_id ? chatResponse.fields.chat_top_message_id : chatResponse.localProperties.chat_top_message_id;

            if (this.replyToTopMessageId) {
                this.replyToAuthor = chatResponse.fields.author ? chatResponse.fields.author : chatResponse.localProperties.author;
            }
        },
        flushReply() {
            this.replyToAuthor = null;
            this.replyToTopMessageId = null;
        },
	},
	beforeMount: function() {
	},
	mounted: async function() {
        setInterval(()=>{
            if (this.suiMaster && this.suiMaster.address) {
                this.canSend = true;
            } else {
                this.canSend = false;
            }
        }, 500);

        this.initChatModel();
	},
}
</script>
