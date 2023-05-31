import { defineAsyncComponent } from 'vue';

// Async component with options
const component = defineAsyncComponent({
    loader: () => import('./SuiSync.vue'),
    delay: 2000,
    timeout: 15000,
});

export default component;
