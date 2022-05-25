// Persistent logger keeping track of what is going on.

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import TextLoggerModule "TextLogger";
import Logger "mo:ic-logger/Logger";

actor{
  // let OWNER = msg.caller;

  type TextLogger = TextLoggerModule.TextLogger;
  let MAX_LINES : Nat = 50;

  var canCount : Nat = 0;
  var canisters = Buffer.Buffer<TextLogger>(0);

  // Principals that are allowed to log messages.
  // stable var allowed : [Principal] = [OWNER];

  // Set allowed principals.
  // public shared (msg) func allow(ids: [Principal]) {
  //   assert(msg.caller == OWNER);
  //   allowed := ids;
  // };

  // Add a set of messages to the log.
  public shared (msg) func append(msgs: [Text]) : async () {
    // assert(Option.isSome(Array.find(allowed, func (id: Principal) : Bool { msg.caller == id })));
    let logger = switch(canCount){
      case (0) {
        let l = await TextLoggerModule.TextLogger(0);
        canisters.add(l);
        canCount := 1;
        canisters.get(0)
      };
      case _ canisters.get(canCount - 1);
    };

    var messages : [Text] = msgs;
    messages := await logger.append(messages);
    while (messages.size() > 0) {
      let logger = await TextLoggerModule.TextLogger(canCount * MAX_LINES);
      canisters.add(logger);
      canCount += 1;
      Debug.print("canisters.size:" # Nat.toText(canisters.size()));
      messages := await logger.append(messages);
    }
  };

  // Return the messages between from and to indice (inclusive).
  public shared (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
    // assert(msg.caller == OWNER);
    assert(canisters.size() > 0);
    assert(canCount > 0);
    assert(from <= to);
    var textArray : [Text] = [];

    var startIndex = from / MAX_LINES;
    let endIndex = to / MAX_LINES;
    Debug.print("canisters.size:" # Nat.toText(canisters.size()));
    Debug.print("start:" # Nat.toText(startIndex) # "---end:" # Nat.toText(endIndex));
    while (startIndex <= endIndex and startIndex < canisters.size()){
      let viewPart = await canisters.get(startIndex).view(from, to);
      startIndex += 1;
      textArray := Array.append<Text>(textArray, viewPart.messages);
    };
      
    {
      start_index = from; 
      messages = textArray;
    }
  };

  // Return log stats, where:
  //   start_index is the first index of log message.
  //   bucket_sizes is the size of all buckets, from oldest to newest.
  // public query func stats() : async Logger.Stats {
  //   logger.stats()
  // };



  // Drop past buckets (oldest first).
  // public shared (msg) func pop_buckets(num: Nat) {
  //   assert(msg.caller == OWNER);
  //   logger.pop_buckets(num)
  // }
}
