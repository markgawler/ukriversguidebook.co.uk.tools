console.log('Loading event');

var aws = require('aws-sdk');
var ddb = new aws.DynamoDB({params: {TableName: 'emailBounce'}});
 
exports.handler = function(event, context) {
  var SnsMessage = event.Records[0].Sns.Message;
 
  var MessageContent = JSON.parse(SnsMessage);

  var NotifyType = MessageContent.notificationType;
  var bounceObject = MessageContent.bounce;
  var mailObject = MessageContent.mail;
  var bouncedRecipients = MessageContent.bounce.bouncedRecipients[0].emailAddress;
  
  var SnsPublishTime = event.Records[0].Sns.Timestamp;
  console.log(bouncedRecipients);
  var itemParams = {Item: {RecipientsEmail: {S: bouncedRecipients},
  SnsPublishTime: {S: SnsPublishTime}, 
  NotifyType: {S: NotifyType},
  Bounce: {S: JSON.stringify(bounceObject)},
  Mail: {S: JSON.stringify(mailObject)}
  }};
 
  ddb.putItem(itemParams, function(err,data) {
      if (err) {
           context.done(err,'Fail');
       }
       else
       {
           context.done(null,'OK');
       }
 }); 
};