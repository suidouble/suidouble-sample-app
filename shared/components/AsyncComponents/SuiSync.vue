<template>

	<div></div>

</template>


<script>
const { SuiInBrowser } = require('suidouble');

export default {
	name: 'SuiSync',
	data() {
		return {
			connectedAddress: null,
            connectedChain: null,

            adapters: [],
            suiInBrowser: null,
            suiMaster: null,
            lastSuiMasterInstanceN: null,
		}
	},
	emits: ['connect', 'connected', 'loaded', 'disconnected', 'error', 'suiMaster'],
	components: {
	},
	watch: {
	},
	methods: {
        async reinitSueMaster() {
            // const suiMaster = new SuiMaster({
            //     signer: this.suiInBrowser,
            //     provider: this.suiInBrowser.provider,
            //     debug: true,
            // });

            // console.log(suiMaster);
            this.suiMaster = await this.suiInBrowser.getSuiMaster();
            if (!this.lastSuiMasterInstanceN || this.lastSuiMasterInstanceN != this.suiMaster.instanceN) {
                this.$emit('suiMaster', this.suiMaster);
            }
            // await suiMaster.requestSuiFromFaucet();
            // await suiMaster.getBalance();

            // const pkg = suiMaster.package({
            //     id: '0x1bd7caaec912286f5e61bab0462020e9f3f389bf5b5474c70400f6575dbb05bd',
            // });

            // let chatShopObjectId = null;
            // if (pkg.localProperties.chatShopObjectId) {
            //     console.error('already here', pkg.localProperties.chatShopObjectId);

            //     chatShopObjectId = pkg.localProperties.chatShopObjectId;
            // } else {

            //     const createdEventsResponse = await pkg.fetchEvents('chat', {eventTypeName: 'ChatShopCreated', order: 'ascending'});
            //     chatShopObjectId = createdEventsResponse.data[0].parsedJson.id;

            //     pkg.localProperties.chatShopObjectId = chatShopObjectId;
            //     console.error('got here', pkg.localProperties.chatShopObjectId);
            // }

            // console.log('createdEventsResponse', createdEventsResponse.data);

            // const pkg = await this.suiInBrowser.suiMaster.package({
            //     id: '0x07c8236b9e412876dfd00c854082786a44ee127d2c9d476766a9104bd68ca9b4',
            // });
            // await pkg.isOnChain();

            // const createdEventsResponse = await pkg.modules.chat.fetchEvents({eventTypeName: 'ChatShopCreated', order: 'ascending'});
            // console.log(createdEventsResponse.data);
            // const chatShopObjectId = createdEventsResponse.data[0].parsedJson.id;

            // let secondUserCallResult = await pkg.moveCall('chat', 'post', [chatShopObjectId, 'I am from the browser', 'metadata']);
            // console.log('secondUserCallResult', secondUserCallResult);
        }
	},
	mounted: function() {
        this.suiInBrowser = SuiInBrowser.getSingleton({
            debug: true,
        });
        this.adapters = Object.values(this.suiInBrowser.adapters);
        this.suiInBrowser.addEventListener('adapter', (e)=>{
            this.adapters.push(e.detail);
        });
        this.suiInBrowser.addEventListener('connected', ()=>{
            this.connectedAddress = this.suiInBrowser.connectedAddress;
            this.connectedChain = this.suiInBrowser.connectedChain;
            this.reinitSueMaster();

            this.$emit('connected', this.suiInBrowser);
        });
        this.suiInBrowser.addEventListener('disconnected', ()=>{
            this.connectedAddress = null;
            this.connectedChain = null;

            this.$emit('disconnected');
        });

		this.$emit('loaded',this.suiInBrowser);
        // console.log(this.suiInBrowser);
        // console.log(this.suiInBrowser.isConnected);
        if (this.suiInBrowser.isConnected) {
            this.connectedAddress = this.suiInBrowser.connectedAddress;
            this.connectedChain = this.suiInBrowser.connectedChain;
            this.reinitSueMaster();

            this.$emit('connected', this.suiInBrowser);
        }

        this.reinitSueMaster();
	},
	computed: {
	}
}
</script>


<style>


</style>