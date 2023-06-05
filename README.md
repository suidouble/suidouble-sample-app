# suidouble-sample-app

Very simple chat application to demonstrate [suidouble](https://github.com/suidouble/suidouble) library in action.

- [check it out online](https://suidouble-sample-app.herokuapp.com/). Note: it's on free heroku instance, may take few seconds to load

Stack: Sui + suidouble + Vue

Code pieces to take a look at:

- smart contract: [chat.move](move/chat/sources/chat.move)
- [async suidouble+sui library component](shared/components/AsyncComponents/SuiAsync.js) 
- [connect button](shared/components/Auth/SignInWithSui.vue) 
- [sui blockchain chat components](frontend/src/components) 
- deploy smart contract script - [deploy_contract.js](deploy_contract.js)
- run integration tests - [test_the_move_contract.test.js](test/test_the_move_contract.test.js)

### executing integration tests:

```bash
npm run test
```
