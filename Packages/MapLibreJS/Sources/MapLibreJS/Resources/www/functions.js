// перенаправление критических логов из JS в Swift
// только error/warn отправляются в Native для снижения нагрузки на bridge
(function() {
  const criticalMethods = ['error', 'warn'];

  criticalMethods.forEach(method => {
    const oldMethod = console[method];
    console[method] = function(...args) {
      oldMethod.apply(console, args);
      try {
        window.webkit.messageHandlers.console.postMessage({
          type: method,
          message: args.map(a => typeof a === 'string' ? a : JSON.stringify(a)).join(' ')
        });
      } catch (e) {}
    };
  });

  // специальный метод для отправки важных событий в Native
  // используется для "Map loaded successfully" и других критических событий
  const oldLog = console.log;
  console.log = function(...args) {
    oldLog.apply(console, args);
    const message = args.join(' ');
    // отправляем только критические события загрузки
    if (message.includes('Map loaded successfully')) {
      try {
        window.webkit.messageHandlers.console.postMessage({
          type: 'log',
          message: message
        });
      } catch (e) {}
    }
  };
})();
