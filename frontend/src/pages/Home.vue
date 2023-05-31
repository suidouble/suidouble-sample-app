<template>

  <div>
    <div class="row">
        <div class="col-12 col-md-3"></div>
        <div class="col-12 col-md-6">
            <div class="text-center">
                <SignInWithSui auto @suiMaster="onSuiMaster" />
            </div>
            <SuiChat :suiMaster="suiMaster" v-if="suiMaster" />
        </div>
        <div class="col-12 col-md-3"></div>
    </div>



  </div>

</template>

<script>
import SignInWithSui from 'shared/components/Auth/SignInWithSui';
import SuiChat from '../components/SuiChat';


export default {
	name: 'Home',
    path: '/',
	props: {
	},
    components: {
        // SuiAsync,
        SignInWithSui,
        SuiChat,
    },
	data() {
		return {
            suiMaster: null,
		}
	},
    watch: {
    },
	methods: {
        async onSuiMaster(suiMaster) {
            this.suiMaster = suiMaster;
        } 
	},
    computed: {
        authenticated() {
            return (!!this.$store.sessionUser.me);
        }
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

