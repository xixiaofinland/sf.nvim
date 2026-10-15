trigger AccountTrigger on Account(before insert) {
  for (Account a : Trigger.new) {
    a.Description = 'created by trigger';
  }
}
