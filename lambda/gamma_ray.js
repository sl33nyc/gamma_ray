const Promise = require('bluebird'),
      domain = require('domain'),
      fs = require('fs'),
      AWS = require('aws-sdk'),
      s3 = new AWS.S3({region: 'us-east-1'});

console.info("LOADING FUNCTIONS");

function json_print(value) {
  return JSON.stringify(value, null, 2);
}

function handler(event, context, callback) {
  var d = domain.create();
  d.on('error', (er) => { console.error('error', er.stack); });
  d.run(() => {
    return Promise.all(event.Records.map(record =>
      handlePayload(new Buffer(record.kinesis.data, 'base64').toString('utf8'))
    ))
      .then((values) => {
        var str = "Successfully processed " + event.Records.length + " records.";
        console.log(str);
        context.succeed(str);
      })
      .catch((err) => {
        var str = "Error processing " + event.Records.length + " records: " + err;
        console.log(str);
        context.succeed(str);
      })
  });
}

function handlePayload(payloadStr) {
  return parseJSON(payloadStr)
  .then(_checkIfBucketExists)
  .then(_createBucket)
  .then(_sendToS3);
}

function _checkIfBucketExists(payload) {
  return new Promise((fulfill, reject) => {
    console.log(json_print(payload));
    var params = { Bucket: getBucketName(payload) };

    s3.headBucket(params, function(err, data) {
      var bucketExists = false;
      if (!err) {
        bucketExists = true;
      }
      return fulfill(payload, bucketExists);
    });
  });
}

function _createBucket(payload, bucketExists) {
  return new Promise((fulfill, reject) => {
    if (bucketExists) {
      return fulfill(payload);
    }

    var params = { Bucket: getBucketName(payload) };
    s3.createBucket(params, function(err, data) {
      if (err) {
        return reject(err);
      } else {
        return fulfill(payload);
      }
    });
  });
}

function _sendToS3(payload) {
  return new Promise((fulfill, reject) => {
    var params  = { ContentType: 'text/plain', Bucket: getBucketName(payload), Key: buildPath(payload), Body: json_print(payload) },
        options = { partSize: 10 * 1024 * 1024, queueSize: 1 };
    s3.upload(params, options, function(err, data) {
      if (err) {
        return reject(err);
      } else {
        return fulfill();
      }
    });
  });
}

function buildPath(payload) {
  var idString = ("000000000" + payload.id).slice(-9);
  var idArray = idString.match(/.{1,3}/g).join("/");
  return payload.table_name + '/' + idArray + '/' + payload.uuid + '.json';
}

function getBucketName(payload) {
  return payload.bucket_name;
}

function parseJSON(json) {
  const parsePromise = new Promise((resolve, reject) => {
    try {
      resolve(JSON.parse(json));
    } catch (e) {
      reject(new Error(`Invalid JSON: ${json}`));
    }
  });

  return parsePromise;
}

exports.handler = handler;
