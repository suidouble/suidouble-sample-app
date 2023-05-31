<template>

	<q-btn type="button" ripple color="primary" :loading="isLoading" @click="onClick">
		<span v-if="!connectedAddress">Connect with Sui</span>
		<span v-if="connectedAddress">Connected as {{ displayAddress }} ({{ connectedChain }})</span>
	</q-btn>

    <q-dialog v-model="showAdaptersDialog" position="top">
        <q-card style="width: 50%;">
            <!-- <q-card-section>
            <div class="text-h6">Alert</div>
            </q-card-section> -->
            <q-card-section>
                <q-list>
                    <template v-for="(adapter, index) in adapters" v-bind:key="index">
                        <q-item
                            clickable
                            v-ripple
                            @click="onAdapterClick(adapter)"
                            v-if="adapter.isDefault || adapter.okForSui"
                            :class="{not_installed: (adapter.isDefault)}"
                            >
                            <q-item-section avatar><q-img :src="adapter.icon" /></q-item-section>
                            <q-item-section class="row"><span color="text-primary">{{ adapter.name }}</span></q-item-section>
                        </q-item>
                    </template>
                </q-list>
            </q-card-section>
        </q-card>
    </q-dialog>

    <SuiAsync @suiMaster="onSuiMaster" @loaded="onLibsLoaded" @connected="onConnected" @disconnected="onDisconnected" v-if="libsRequested" ref="sui"/>

</template>

<style lang="css" scoped>
    .not_installed {
        opacity: 0.6;
    }
</style>

<script>
import SuiAsync from 'shared/components/AsyncComponents/SuiAsync';

export default {
	name: 'SignInWithSui',
    emits: ['suiMaster'],
	props: {
        auto: {
            default: false,
            type: Boolean,
        }
	},
	data() {
		return {
			isLoading: false,
            libsRequested: false,
            showAdaptersDialog: false,

            adapters: [],
            connectedAddress: null,
            connectedChain: null,
		}
	},
	watch: {
	},
	computed: {
		displayAddress() {
			return (''+this.connectedAddress).substr(0,6)+'...'+(''+this.connectedAddress).substr(-4);
		},
	},
	components: {
        SuiAsync,
	},
	methods: {
        /**
         * SuiMaster instance updated
         * @param {SuiMaster} suiMaster 
         */
        onSuiMaster(suiMaster) {
            this.$emit('suiMaster', suiMaster);
        },
        async onAdapterClick(adapter) {
            if (adapter.isDefault && !adapter.isInstalled) {
                window.open(adapter.getDownloadURL(), '_blank');
                return false;
            }

            this.isLoading = true;
            this.showAdaptersDialog = false;
            await this.$refs.sui.suiInBrowser.connect(adapter);
            this.isLoading = false;
        },
        async onClick() {
            this.isLoading = true;
            await this.requestLibs();
            await new Promise((res)=>{ setTimeout(res, 200); }); // let providers check if we are already connected

            if (!this.connectedAddress) {
                this.showAdaptersDialog = true;
            }

            this.isLoading = false;
        },
		async initialize() {
            if (this.auto) {
                this.isLoading = true;
                await this.requestLibs();
                this.isLoading = false;
            }
		},
        async requestLibs() {
            this.libsRequested = true;
            await this.__libsRequestedPromise;
            this.adapters = this.$refs.sui.adapters;
        },
        onLibsLoaded() {
            this.__libsRequestedPromiseResolver();
        },
        onConnected() {
            this.connectedAddress = this.$refs.sui.suiInBrowser.connectedAddress;
            this.connectedChain = this.$refs.sui.suiInBrowser.connectedChain;
        },
        onDisconnected() {
            this.connectedAddress = null;
        },
	},
	beforeMount: function() {
        this.__libsRequestedPromiseResolver = null;
        this.__libsRequestedPromise = new Promise((res)=>{
            this.__libsRequestedPromiseResolver = res;
        });
	},
	mounted: async function() {
		this.initialize();
	},
}
</script>
