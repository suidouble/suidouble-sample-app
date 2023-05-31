const { SuiMaster } = require('suidouble');
const path = require('path');

const run = async ()=>{
    const provider = 'test';

    const suiMaster = new SuiMaster({ debug: true, as: 'admin', provider: provider, });

    await suiMaster.requestSuiFromFaucet();
    await suiMaster.getBalance();

    const package = suiMaster.addPackage({
        path: path.join(__dirname, 'move/chat'),
    });

    await package.publish();

    console.log('deployed as', package.id);
};

run()
    .then(()=>{
        console.log('done');
    });
