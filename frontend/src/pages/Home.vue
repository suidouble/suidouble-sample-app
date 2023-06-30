<template>

  <div>
    <div class="row">
        <div class="col-12 col-md-4">
            <p>Sample demo application of <a href="https://github.com/suidouble/suidouble">suidouble</a> library components for interaction with <a href="https://sui.io" target="_blank">Sui</a> blockchain.</p>

            <p>Available on mainnet, devnet and testnet. You can switch the chain in wallet extension.</p>

            <p>Check out on github:</p>

            <ul>
                <li><a href="https://github.com/suidouble/suidouble-sample-app/blob/main/move/chat/sources/chat.move">Sui Move contract source code</a></li>
                <li><a href="https://github.com/suidouble/suidouble">suidouble library</a></li>
                <li><a href="https://github.com/suidouble/suidouble-sample-app">this dapp source code</a></li>
            </ul>
        </div>
        <div class="col-12 col-md-8">
            <div class="text-center">
                <SignInWithSuiButton auto @suiMaster="onSuiMaster" :defaultChain="defaultChain" @wrongchain="onOtherChain" />
            </div>
            <SuiChat :suiMaster="suiMaster" v-if="suiMaster"  />
        </div>
    </div>



  </div>

</template>

<script>
import { SignInWithSuiButton } from 'vue-sui';
import SuiChat from '../components/SuiChat';


export default {
	name: 'Home',
    path: '/',
	props: {
	},
    components: {
        // SuiAsync,
        SignInWithSuiButton,
        SuiChat,
    },
	data() {
		return {
            suiMaster: null,
            defaultChain: 'sui:mainnet',
		}
	},
    watch: {
    },
	methods: {
        async onSuiMaster(suiMaster) {
            this.suiMaster = suiMaster;
        },
        async onOtherChain(walletIsConnectedTo) {
            this.suiMaster = null;
            this.defaultChain = walletIsConnectedTo;
        }
	},
    computed: {
    },
    beforeMount() {
    },
    mounted() {
    },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
    h6 {
        font-size: 16px;
        font-weight: bold;
        margin: 0 0 16px 0;
    }

    h5 {
        margin: 0 0 16px 0;
    }

</style>

