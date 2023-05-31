// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module object_display::chat {
    // use std::ascii::{Self, String};
    // use std::option::{Self, Option, some};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector::length;

    use sui::dynamic_object_field::{Self};
    // use object_display::typed_id::{Self, TypedID};

    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    
    use std::debug;

    use sui::event::emit;

    /// Max text length.
    const MAX_TEXT_LENGTH: u64 = 512;

    /// Text size overflow.
    const ETextOverflow: u64 = 0;

    // ======== Events =========

    /// Event. When a new chat has been created.
    struct ChatShopCreated has copy, drop { id: ID }
    struct ChatTopMessageCreated has copy, drop { id: ID, top_response_id: ID }
    struct ChatResponseCreated has copy, drop { id: ID, top_message_id: ID, seq_n: u64 }

    /// Capability that grants an owner the right to collect profits.
    struct ChatOwnerCap has key { id: UID }

    /// A shared object. `key` ability is required.
    struct ChatShop has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>
    }

    struct ChatTopMessage has key, store {
        id: UID,
        chat_shop_id: ID,
        chat_top_response_id: ID,
        author: address,
        // text: String,
        // app-specific metadata. We do not enforce a metadata format and delegate this to app layer.
        // metadata: vector<u8>,
        responses_count: u64,
    }

    struct ChatResponse has key, store {
        id: UID,
        chat_top_message_id: ID,
        author: address,
        text: vector<u8>,
        // app-specific metadata. We do not enforce a metadata format and delegate this to app layer.
        metadata: vector<u8>,
        seq_n: u64, // n of message in thread
    }

    // /// Sui Chat NFT (i.e., a post, retweet, like, chat message etc).
    // struct ChatMessage has key, store {
    //     id: UID,
    //     // The ID of the chat app.
    //     chat_shop_id: ID,
    //     // Author address
    //     author: address,
    //     // Post's text.
    //     text: String,
    //     // Set if referencing an another object (i.e., due to a Like, Retweet, Reply etc).
    //     // We allow referencing any object type, not only Chat NFTs.
    //     ref_id: Option<address>,
    //     // app-specific metadata. We do not enforce a metadata format and delegate this to app layer.
    //     metadata: vector<u8>,
    // }

    // struct ChatMessageShared has key, store {
    //     id: UID,
    // }

    /// Init function is often ideal place for initializing
    /// a shared object as it is called only once.
    ///
    /// To share an object `transfer::share_object` is used.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(ChatOwnerCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        let id = object::new(ctx);
        emit(ChatShopCreated { id: object::uid_to_inner(&id) });

        // Share the object to make it accessible to everyone!
        transfer::share_object(ChatShop {
            id: id,
            price: 1000,
            balance: balance::zero()
        })
    }

    // /// Simple Chat.text getter.
    // public fun text(chat_message: &ChatMessage): String {
    //     chat_message.text
    // }

//     /// Mint (post) a Chat object.
//     fun post_internal(
//         chat_shop: &ChatShop,
//         text: vector<u8>,
//         ref_id: Option<address>,
//         metadata: vector<u8>,
//         ctx: &mut TxContext,
//     ) : ChatMessageShared {
//         assert!(length(&text) <= MAX_TEXT_LENGTH, ETextOverflow);
//         let id = object::new(ctx);
//         let shared_id = object::new(ctx);

//         // emit(ChatMessageCreated { id: object::uid_to_inner(&id), top: option::none() });
//         emit(ChatMessageCreated { id: object::uid_to_inner(&id), top: option::some(object::uid_to_inner(&shared_id)) });

//         let chat_message = ChatMessage {
//             id: id,
//             chat_shop_id: object::id(chat_shop),
//             author: tx_context::sender(ctx),
//             text: ascii::string(text),
//             ref_id,
//             metadata,
//         };

//         // let chat_message_id = typed_id::new(&chat_message);
        
//         debug::print(&chat_message);



//         let chat_message_shared = ChatMessageShared {
//             id: shared_id,
//         };
//         // let shared_id_copy =  object::id(&chat_message_shared);
// // // Adds `b` as a dynamic object field to `a` with "name" `0: u8`.
// // ofield::add<u8, B>(&mut a.id, 0, b);

// // // Get access to `b` at its new position
// // let b: &B = ofield::borrow<u8, B>(&a.id, 0);

//         // dynamic_object_field::add<vector<u8>, ChatMessage>(&mut chat_message_shared.id, b"chat_message", chat_message);
//         dynamic_object_field::add(&mut chat_message_shared.id, b"chat_message", chat_message);

//         debug::print(&chat_message_shared);
//         // option::fill(&mut chat_message_shared.chat_message, chat_message_id);
//         // let b: ChatMessage = ofield::borrow<vector<u8>, ChatMessage>(shared_id, b"chat_message");

//         // let borrowed = ofield::borrow<vector<u8>, ChatMessage>(&mut chat_message_shared.id, b"chat_message");

//         chat_message_shared
//         // transfer::share_object(chat_message_shared);

//         // let c = dynamic_object_field::borrow<vector<u8>, ChatMessage>(shared_id_copy, b"chat_message");
//         // let b: &ChatMessage = dynamic_object_field::borrow<vector<u8>, ChatMessage>(&shared_id_copy, b"chat_message");
//         // transfer::public_transfer(b, tx_context::sender(ctx));
//     }

    /// Mint (post) a chatMessage object without referencing another object.
    public entry fun post(
        chat_shop: &ChatShop,
        text: vector<u8>,
        metadata: vector<u8>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&text) <= MAX_TEXT_LENGTH, ETextOverflow);
        let id = object::new(ctx);
        let chat_response_id = object::new(ctx);

        emit(ChatTopMessageCreated { id: object::uid_to_inner(&id), top_response_id: object::uid_to_inner(&chat_response_id),  });
        emit(ChatResponseCreated { id: object::uid_to_inner(&chat_response_id), top_message_id: object::uid_to_inner(&id), seq_n: 0 });

        let chat_top_message = ChatTopMessage {
            id: id,
            chat_shop_id: object::id(chat_shop),
            author: tx_context::sender(ctx),
            chat_top_response_id: object::uid_to_inner(&chat_response_id),
            responses_count: 0,
            // text: ascii::string(text),
            // metadata,
        };

        // transfer::freeze_object(ChatTopMessage {
        //     id: object::new(ctx),
        //     chat_shop_id: object::id(chat_shop),
        //     author: tx_context::sender(ctx),
        //     chat_top_response_id: object::uid_to_inner(&chat_response_id),
        //     responses_count: 0,
        // });

        let chat_response = ChatResponse {
            id: chat_response_id,
            chat_top_message_id: object::id(&chat_top_message),
            author: tx_context::sender(ctx),
            text: text,
            metadata,
            seq_n: 0,
        };
        dynamic_object_field::add(&mut chat_top_message.id, b"as_chat_response", chat_response);

        // transfer::transfer(chat_top_message, tx_context::sender(ctx));
        transfer::share_object(chat_top_message);
        // transfer::transfer(chat_top_message, tx_context::sender(ctx));
        // let chat_message_shared = post_internal(chat_shop, text, option::none(), metadata, ctx);
        // // let b = dynamic_object_field::borrow<vector<u8>, ChatMessage>(&mut chat_message_shared.id, b"chat_message");
        // // debug::print(b);

        // // let z = &*b;
        // // debug::print(z);

        // // transfer::public_transfer(b, tx_context::sender(ctx));
        // transfer::share_object(chat_message_shared);
    }

    public entry fun reply(
        chat_top_message: &mut ChatTopMessage,
        text: vector<u8>,
        metadata: vector<u8>,
        ctx: &mut TxContext,
    ) {
        assert!(length(&text) <= MAX_TEXT_LENGTH, ETextOverflow);

        let dynamic_field_exists = dynamic_object_field::exists_(&chat_top_message.id, b"as_chat_response");
        if (dynamic_field_exists) {
            let top_level_chat_response = dynamic_object_field::remove<vector<u8>, ChatResponse>(&mut chat_top_message.id, b"as_chat_response");
            transfer::transfer(top_level_chat_response, chat_top_message.author);
        };

        chat_top_message.responses_count = chat_top_message.responses_count + 1;

        let id = object::new(ctx);

        emit(ChatResponseCreated { id: object::uid_to_inner(&id), top_message_id: object::uid_to_inner(&chat_top_message.id), seq_n: chat_top_message.responses_count });

        let chat_response = ChatResponse {
            id: id,
            chat_top_message_id: object::id(chat_top_message),
            author: tx_context::sender(ctx),
            text: text,
            metadata,
            seq_n: chat_top_message.responses_count,
        };

        transfer::transfer(chat_response, tx_context::sender(ctx));
    }

    // /// Mint (post) a chatMessage object and reference another object (i.e., to simulate retweet, reply, like, attach).
    // /// TODO: Using `address` as `app_identifier` & `ref_identifier` type, because we cannot pass `ID` to entry
    // ///     functions. Using `vector<u8>` for `text` instead of `String`  for the same reason.
    // public entry fun post_with_ref(
    //     chat_shop: &ChatShop,
    //     text: vector<u8>,
    //     ref_identifier: address,
    //     metadata: vector<u8>,
    //     ctx: &mut TxContext,
    // ) {
    //     let chat_message_shared = post_internal(chat_shop, text, some(ref_identifier), metadata, ctx);
    //     transfer::share_object(chat_message_shared);
    // }

    // /// Burn a chatMessage object.
    // public entry fun burn(chat_message: ChatMessage) {
    //     let ChatMessage { id, chat_shop_id: _, text: _, author: _, ref_id: _, metadata: _ } = chat_message;
    //     object::delete(id);
    // }


    #[test]
    public fun test_module_init() {
        use sui::test_scenario;

        // Create test address representing game admin
        let admin = @0xBABE;
        let somebody = @0xFAFE;
        let anybody = @0xFAAE;
        // let player = @0x0;

        // First transaction to emulate module initialization
        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        // Run the module initializers
        test_scenario::next_tx(scenario, admin);
        {
            init(test_scenario::ctx(scenario));

        };
        // Run the module initializers
        test_scenario::next_tx(scenario, somebody);
        {
            let chat_shop = test_scenario::take_shared<ChatShop>(scenario);
            // let chat_shop_ref = &chat_shop;
            debug::print(&chat_shop);

            let chat_shop_ref = &chat_shop;
            post(chat_shop_ref, b"test", b"metadata", test_scenario::ctx(scenario));

            // post(chat_shop_ref, b"test", b"metadata", test_scenario::ctx(scenario));

            test_scenario::return_shared(chat_shop);
        };

        test_scenario::next_tx(scenario, anybody);
        {    
            // let chat_top_message = test_scenario::take_from_sender<ChatTopMessage>(scenario);
            let chat_top_message = test_scenario::take_shared<ChatTopMessage>(scenario);
            // let chat_shop_ref = &chat_shop;
            debug::print(&chat_top_message);
            debug::print(&mut chat_top_message);

            // let chat_top_message_ref = &chat_top_message;
            reply(&mut chat_top_message, b"response", b"metadata", test_scenario::ctx(scenario));

            // post(chat_shop_ref, b"test", b"metadata", test_scenario::ctx(scenario));

            test_scenario::return_shared(chat_top_message);
            // test_scenario::return_to_sender(scenario, chat_top_message);
        };

        test_scenario::next_tx(scenario, anybody);
        {    
            // let chat_top_message = test_scenario::take_from_sender<ChatTopMessage>(scenario);
            let chat_top_message = test_scenario::take_shared<ChatTopMessage>(scenario);
            // let chat_shop_ref = &chat_shop;
            debug::print(&mut chat_top_message);

            // let chat_top_message_ref = &chat_top_message;
            reply(&mut chat_top_message, b"response", b"metadata", test_scenario::ctx(scenario));

            // post(chat_shop_ref, b"test", b"metadata", test_scenario::ctx(scenario));

            test_scenario::return_shared(chat_top_message);
            // test_scenario::return_to_sender(scenario, chat_top_message);
        };
        // Player purchases a hero with the coins
        // test_scenario::next_tx(scenario, admin);
        // {
        //     let chat_shop = test_scenario::take_immutable<ChatShop>(scenario);
        //     // let chat_shop_ref = &chat_shop;
        // debug::print(&chat_shop);

        //     // post(chat_shop_ref, b"test", b"metadata", test_scenario::ctx(scenario));

        //     test_scenario::return_immutable(chat_shop);

        //     // let game_ref = &game;
        //     // let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
        //     // acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
        //     // test_scenario::return_immutable(game);
        // };

        // let scenario = &mut scenario_val;
        // {
        //     init(test_scenario::ctx(scenario));
        //     let chat_shop = test_scenario::take_immutable<ChatShop>(scenario);
        //     debug::print(&chat_shop);

        //     test_scenario::return_immutable(chat_shop);
        // };
        // Second transaction to check if the forge has been created
        // and has initial value of zero swords created
        // test_scenario::next_tx(scenario, admin);
        // {
        //     // Extract the ChatShop object
        //     let chat_shop = test_scenario::take_immutable<ChatShop>(scenario);

        //     debug::print(&chat_shop);

        //     post(&mut chat_shop, b"test", b"metadata", test_scenario::ctx(scenario));
        //     // Return the ChatShop object to the object pool
        //     test_scenario::return_to_sender(scenario, chat_shop);
        // };
        test_scenario::end(scenario_val);
    }
}
