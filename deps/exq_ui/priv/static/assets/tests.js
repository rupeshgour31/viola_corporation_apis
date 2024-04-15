'use strict';

define('exqui/tests/adapters/application.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - adapters/application.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'adapters/application.js should pass ESLint.\n');
  });
});
define('exqui/tests/app.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - app.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'app.js should pass ESLint.\n');
  });
});
define('exqui/tests/components/exq-stat.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - components/exq-stat.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'components/exq-stat.js should pass ESLint.\n');
  });
});
define('exqui/tests/components/exq-stats.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - components/exq-stats.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'components/exq-stats.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/application.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/application.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/application.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/failures/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/failures/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/failures/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/processes/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/processes/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/processes/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/queues/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/queues/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/queues/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/retries/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/retries/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/retries/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/controllers/scheduled/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - controllers/scheduled/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'controllers/scheduled/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/helpers/destroy-app', ['exports', 'ember'], function (exports, _ember) {
  exports['default'] = destroyApp;

  function destroyApp(application) {
    _ember['default'].run(application, 'destroy');
  }
});
define('exqui/tests/helpers/destroy-app.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - helpers/destroy-app.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'helpers/destroy-app.js should pass ESLint.\n');
  });
});
define('exqui/tests/helpers/module-for-acceptance', ['exports', 'qunit', 'ember', 'exqui/tests/helpers/start-app', 'exqui/tests/helpers/destroy-app'], function (exports, _qunit, _ember, _exquiTestsHelpersStartApp, _exquiTestsHelpersDestroyApp) {
  var Promise = _ember['default'].RSVP.Promise;

  exports['default'] = function (name) {
    var options = arguments.length <= 1 || arguments[1] === undefined ? {} : arguments[1];

    (0, _qunit.module)(name, {
      beforeEach: function beforeEach() {
        this.application = (0, _exquiTestsHelpersStartApp['default'])();

        if (options.beforeEach) {
          return options.beforeEach.apply(this, arguments);
        }
      },

      afterEach: function afterEach() {
        var _this = this;

        var afterEach = options.afterEach && options.afterEach.apply(this, arguments);
        return Promise.resolve(afterEach).then(function () {
          return (0, _exquiTestsHelpersDestroyApp['default'])(_this.application);
        });
      }
    });
  };
});
define('exqui/tests/helpers/module-for-acceptance.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - helpers/module-for-acceptance.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'helpers/module-for-acceptance.js should pass ESLint.\n');
  });
});
define('exqui/tests/helpers/resolver', ['exports', 'exqui/resolver', 'exqui/config/environment'], function (exports, _exquiResolver, _exquiConfigEnvironment) {

  var resolver = _exquiResolver['default'].create();

  resolver.namespace = {
    modulePrefix: _exquiConfigEnvironment['default'].modulePrefix,
    podModulePrefix: _exquiConfigEnvironment['default'].podModulePrefix
  };

  exports['default'] = resolver;
});
define('exqui/tests/helpers/resolver.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - helpers/resolver.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'helpers/resolver.js should pass ESLint.\n');
  });
});
define('exqui/tests/helpers/start-app', ['exports', 'ember', 'exqui/app', 'exqui/config/environment'], function (exports, _ember, _exquiApp, _exquiConfigEnvironment) {
  exports['default'] = startApp;

  function startApp(attrs) {
    var attributes = _ember['default'].merge({}, _exquiConfigEnvironment['default'].APP);
    attributes = _ember['default'].merge(attributes, attrs); // use defaults, but you can override;

    return _ember['default'].run(function () {
      var application = _exquiApp['default'].create(attributes);
      application.setupForTesting();
      application.injectTestHelpers();
      return application;
    });
  }
});
define('exqui/tests/helpers/start-app.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - helpers/start-app.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'helpers/start-app.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/custom-inflector-rules.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/custom-inflector-rules.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/custom-inflector-rules.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/failure.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/failure.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/failure.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/job.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/job.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/job.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/process.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/process.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/process.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/queue.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/queue.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/queue.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/realtime.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/realtime.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/realtime.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/retry.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/retry.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/retry.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/scheduled.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/scheduled.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/scheduled.js should pass ESLint.\n');
  });
});
define('exqui/tests/models/stat.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - models/stat.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'models/stat.js should pass ESLint.\n');
  });
});
define('exqui/tests/resolver.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - resolver.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'resolver.js should pass ESLint.\n');
  });
});
define('exqui/tests/router.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - router.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'router.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/application.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/application.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/application.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/failures/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/failures/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/failures/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/processes/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/processes/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/processes/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/queues/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/queues/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/queues/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/queues/show.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/queues/show.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/queues/show.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/retries/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/retries/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/retries/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/routes/scheduled/index.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - routes/scheduled/index.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'routes/scheduled/index.js should pass ESLint.\n');
  });
});
define('exqui/tests/test-helper', ['exports', 'exqui/tests/helpers/resolver', 'ember-qunit'], function (exports, _exquiTestsHelpersResolver, _emberQunit) {

  (0, _emberQunit.setResolver)(_exquiTestsHelpersResolver['default']);
});
define('exqui/tests/test-helper.lint-test', ['exports'], function (exports) {
  'use strict';

  QUnit.module('ESLint - test-helper.js');
  QUnit.test('should pass ESLint', function (assert) {
    assert.expect(1);
    assert.ok(true, 'test-helper.js should pass ESLint.\n');
  });
});
require('exqui/tests/test-helper');
EmberENV.TESTS_FILE_LOADED = true;
//# sourceMappingURL=tests.map
