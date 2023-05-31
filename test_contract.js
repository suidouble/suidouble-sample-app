const { SuiTestScenario } = require('suidouble');
const path = require('path');
const assert = require('node:assert/strict');

const testData = {
    messages: ['hello', 'hi', 'yo', 'hey there', 'hey everybody'],
    responses: ['hmm', 'ooookay', 'k', 'who are you?', 'booom!'],
};

const run = async ()=>{
    console.log('testing the package on local node');

    const testScenario = new SuiTestScenario({
        path: path.join(__dirname, 'move/chat'),
        debug: true,
    });

    await testScenario.begin('admin');
    await testScenario.init();

    await testScenario.nextTx('admin', async()=>{
        const chatShop = testScenario.takeShared('ChatShop');
        await testScenario.moveCall('chat', 'post', [chatShop.address, 'posting a message', 'metadata']);
        const chatTopMessage = testScenario.takeShared('ChatTopMessage');

        assert.equal(!!chatTopMessage.id, true);
        console.log(chatTopMessage.id, 'posted');
    });

    await testScenario.nextTx('somebody', async()=>{
        const chatTopMessage = testScenario.takeShared('ChatTopMessage');
        await testScenario.moveCall('chat', 'reply', [chatTopMessage.address, 'posting a response', 'metadata']);
        const chatResponse = testScenario.takeFromSender('ChatResponse');

        assert.equal(!!chatResponse.id, true);
        assert.equal(chatResponse.fields.chat_top_message_id, chatTopMessage.id);
    });

    await testScenario.end();
};

run()
    .then(()=>{
        console.log('done');
    });