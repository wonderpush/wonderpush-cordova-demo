module.exports = function(ctx) {
  if (ctx.cmdLine.indexOf('android') === -1) {
    return;
  }

  var fs = ctx.requireCordovaModule('fs');
  var path = ctx.requireCordovaModule('path');
  var root = ctx.opts.projectRoot;
  var origin = path.join(root, 'scripts', 'android.gradle');
  var destination = path.join(root, 'platforms', 'android', 'build-extras.gradle');

  console.log('Add ', origin, ' to ', destination);

  fs.createReadStream(origin).pipe(fs.createWriteStream(destination));
};
