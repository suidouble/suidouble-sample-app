'use strict'

const t = require('tap');
const { test } = t;
const path = require('path');

const { SuiTestScenario } = require('suidouble');

let testScenario = null;

test('initialization', async t => {
    testScenario = new SuiTestScenario({
        path: path.join(__dirname, '../move/chat/'),
        debug: false,
    });

    await testScenario.begin('admin');
    await testScenario.init();

    t.equal(testScenario.currentAs, 'admin');
});

test('posting a message', async t => {
	// t.plan(4); // optional to be sure everything executed inside testScenario.nextTx

    await testScenario.nextTx('admin', async()=>{
        const chatShop = testScenario.takeShared('ChatShop');

        t.ok(chatShop.address); // there should be some address
        t.ok(`${chatShop.address}`.indexOf('0x') === 0); // adress is string starting with '0x'

        await testScenario.moveCall('chat', 'post', [chatShop.address, 'posting a message', 'metadata']);
        const chatTopMessage = testScenario.takeShared('ChatTopMessage');

        t.ok(chatTopMessage.address); // there should be some address
        t.ok(`${chatTopMessage.address}`.indexOf('0x') === 0); // adress is string starting with '0x'

        // we are posting the text as the very first response to ChatTopMessage
        const chatTopMessageFieldsResponse = await chatTopMessage.getDynamicFields();

        let foundChatResponseId = null;
        await chatTopMessageFieldsResponse.forEach((item)=>{
            if (item.objectType && item.objectType.indexOf('ChatResponse') !== -1) {
                foundChatResponseId = item.objectId;
            }
        });

        t.ok(foundChatResponseId);
    });
});

test('posting a reponse', async t => {
	// t.plan(3);

    await testScenario.nextTx('somebody', async()=>{
        const chatTopMessage = testScenario.takeShared('ChatTopMessage');
        t.ok(chatTopMessage.address); // there should be some address

        await testScenario.moveCall('chat', 'reply', [chatTopMessage.address, 'posting a response', 'metadata']);
        const chatResponse = testScenario.takeFromSender('ChatResponse');

        t.ok(chatResponse.address); // there should be some address
        t.ok(`${chatResponse.address}`.indexOf('0x') === 0); // adress is string starting with '0x'

        // messageTextAsBytes = [].slice.call(new TextEncoder().encode(messageText)); // regular array with utf data
        // chat contract store text a bytes (easier to work with unicode things), let's convert it back to js string

        const foundText = new TextDecoder().decode(new Uint8Array(chatResponse.fields.text));
        t.equal(foundText, "posting a response"); 
    });
})

test('finishing the test scenario', async t => {
    await testScenario.end();
});
