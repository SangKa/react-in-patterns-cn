# 依赖注入

我们写的好多模块和组件都有依赖。能否管理这些依赖对于项目的成功至关重要。有一种叫做 [*依赖注入*](http://krasimirtsonev.com/blog/article/Dependency-injection-in-JavaScript) 的技术 (大多数人认为它是一种*模式*) 用来解决这种问题。

在 React 中，对依赖注入的需要是显而易见的。我们来考虑下面的应用的组件树:

```js
// Title.jsx
export default function Title(props) {
  return <h1>{ props.title }</h1>;
}

// Header.jsx
import Title from './Title.jsx';

export default function Header() {
  return (
    <header>
      <Title />
    </header>
  );
}

// App.jsx
import Header from './Header.jsx';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { title: 'React in patterns' };
  }
  render() {
    return <Header />;
  }
};
```

字符串 "React in patterns" 应该以某种方式到达 `Title` 组件。最直接的方式就从 `App` 传到 `Header` ，再从 `Header` 传到 `Title` 。但是，对于三层组件还好，但是如果嵌套的层级很深，并且需要传多个属性呢？大多数组件都扮演着代理的角色，将属性转发给子组件。

我们已经了解过 [高阶组件](../chapter-4/README.md#%E9%AB%98%E9%98%B6%E7%BB%84%E4%BB%B6) ，它可以用来注入数据。我们来使用同样的技术来注入 `title` 变量:

```js
// inject.jsx
const title = 'React in patterns';

export default function inject(Component) {
  return class Injector extends React.Component {
    render() {
      return (
        <Component
          {...this.props}
          title={ title }
        />
      )
    }
  };
}

// -----------------------------------
// Header.jsx
import inject from './inject.jsx';
import Title from './Title.jsx';

var EnhancedTitle = inject(Title);
export default function Header() {
  return (
    <header>
      <EnhancedTitle />
    </header>
  );
}
```

`title` 隐藏在了中间层 (高阶组件) ，在中间层我们将 `title` 属性传给了原始的 `Title` 组件。一切都很不错，但它只解决了一半问题。现在我们不再需要在组件树中将 `title` 向下层层传递，但是需要考虑数据如何到达 `inject.jsx` 辅助函数。

## 使用 React context (16.3 之前的版本)

*在 React 16.3 版本中，React 团队引入了新版的 context API ，如果你想使用新版 API ，那么可以跳过此节。*

React 有 [*context*](https://facebook.github.io/react/docs/context.html) 的概念。每个 React 组件都可以访问 *context* 。它有些类似于 [事件总线](https://github.com/krasimir/EventBus) ，但是为数据而生。可以把它想象成在任意地方都可以访问的单一 *store* 。

```js
// 定义 context 的地方
var context = { title: 'React in patterns' };

class App extends React.Component {
  getChildContext() {
    return context;
  }
  ...
};
App.childContextTypes = {
  title: React.PropTypes.string
};

// 使用 context 的地方
class Inject extends React.Component {
  render() {
    var title = this.context.title;
    ...
  }
}
Inject.contextTypes = {
  title: React.PropTypes.string
};
```

注意，我们需要使用 `childContextTypes` 和 `contextTypes` 来指定 context 对象的具体签名。如果不指定的话，那么 `context` 对象将为空。这点可能有点令人沮丧，因为我们可能会多写很多代码。所以将 `context` 写成允许我们储存和获取数据的服务，而不是一个普通对象是一种最佳实践。例如:

```js
// dependencies.js
export default {
  data: {},
  get(key) {
    return this.data[key];
  },
  register(key, value) {
    this.data[key] = value;
  }
}
```

然后，回到示例中，`App` 组件应该是这样的:

```js
import dependencies from './dependencies';

dependencies.register('title', 'React in patterns');

class App extends React.Component {
  getChildContext() {
    return dependencies;
  }
  render() {
    return <Header />;
  }
};
App.childContextTypes = {
  data: React.PropTypes.object,
  get: React.PropTypes.func,
  register: React.PropTypes.func
};
```

`Title` 组件通过 context 来获取数据:

```js
// Title.jsx
export default class Title extends React.Component {
  render() {
    return <h1>{ this.context.get('title') }</h1>
  }
}
Title.contextTypes = {
  data: React.PropTypes.object,
  get: React.PropTypes.func,
  register: React.PropTypes.func
};
```

理想情况下，我们不想每次需要访问 context` 时都指定 `contextTypes` 。可以使用高阶组件来包装类型细节。但更好的做法是，我们可以编写一个更具描述性的工具函数，从而帮助我们声明确切的类型。例如，我们不再直接使用 `this.context.get('title')` 来访问 context ，而是告诉高阶组件需要传递给组件的属性。例如:

```js
// Title.jsx
import wire from './wire';

function Title(props) {
  return <h1>{ props.title }</h1>;
}

export default wire(Title, ['title'], function resolve(title) {
  return { title };
});
```

`wire` 函数接收 React 组件、所需依赖 (依赖都已经注册过了) 的数组和我喜欢称之为 `mapper` 的转换函数。`mapper` 函数接收存储在 context 中的原始数据，并返回组件 ( `Title` ) 稍后使用的属性。在本例中，我们传入只是字符串，即 `title` 变量。但是，在真正的应用中，这个依赖项可以是大型的数据集合，配置对象或其他东西。

`wire` 函数的代码如下所示:

```js
export default function wire(Component, dependencies, mapper) {
  class Inject extends React.Component {
    render() {
      var resolved = dependencies.map(
        this.context.get.bind(this.context)
      );
      var props = mapper(...resolved);

      return React.createElement(Component, props);
    }
  }
  Inject.contextTypes = {
    data: React.PropTypes.object,
    get: React.PropTypes.func,
    register: React.PropTypes.func
  };
  return Inject;
};
```

`Inject` 是高阶组件，它可以访问 context 并获取 `dependencies` 数组中的所有项。`mapper` 函数接收 `context` 数据并将其转换成我们组建所需要的属性。

## 使用 React context (16.3 及之后的版本)

这些年来，Fackbook 并不推荐使用 context API 。在官方文档中也有提到，此 API 不稳定，随时可能更改。确实也言中了。16.3 版本提供了一个新的 context API ，我认为新版 API 更自然，使用起来也更简单。

我们还是使用同一个示例，让字符串抵达 `<Title>` 组件。

我们先来定义包含 context 初始化的文件:

```js
// context.js
import { createContext } from 'react';

const Context = createContext({});

export const Provider = Context.Provider;
export const Consumer = Context.Consumer;
```

`createContext` 返回的对象具有 `Provider` 和 `Consumer` 属性。它们实际上是有效的 React 类。`Provicer` 以 `value` 属性的形式接收 context 。`Consumer` 用来访问 context 并从中读取数据。因为它们通常存在于不同的文件中，所以单独创建一个文件来进行它们的初始化是个不错的主意。

假设说我们的 `App` 组件是根组件。在此我们需要传入 context 。

```js
import { Provider } from './context';

const context = { title: 'React In Patterns' };

class App extends React.Component {
  render() {
    return (
      <Provider value={ context }>
        <Header />
      </Provider>
    );
  }
};
```

包装组件以及子组件现在共享同一个 context 。`<Title>` 组件是需要 `title` 字符串的组件之一，所以我们要在组件中使用 `<Consumer>` 。

```js
import { Consumer } from './context';

function Title() {
  return (
    <Consumer>{
      ({ title }) => <h1>Title: { title }</h1>
    }</Consumer>
  );
}
```

*注意，`Consumer` 类使用函数作为嵌套子元素 ( render prop 模式) 来传递 context 。*

新的 API 让人感觉更容易理解，同时样板文件代码更少。此 API 仍然还很新，但看起来很有前途。它开启了一系列全新的可能性。

## 使用模块系统

如果不像使用 context 的话，还有一些其他方式来实现注入。它们并非 React 相关的，但是值得一提。方式之一就是使用模块系统。

众所周知，JavaScript 中的典型模块系统具有缓存机制。在 [Node 官方文档](https://nodejs.org/api/modules.html#modules_caching) 中可以看到:

> 模块在第一次加载后会被缓存。这也意味着（类似其他缓存机制）如果每次调用 require('foo') 都解析到同一文件，则返回相同的对象。

> 多次调用 require(foo) 不会导致模块的代码被执行多次。这是一个重要的特性。借助它, 可以返回“部分完成”的对象，从而允许加载依赖的依赖, 即使它们会导致循环依赖。

这对依赖注入有什么帮助吗？当然，如果我们导出一个对象，我们实际上导出的是一个 [单例]((https://addyosmani.com/resources/essentialjsdesignpatterns/book/#singletonpatternjavascript)，并且每个导入该文件的其他模块都将获得同一个对象。这使得我们可以 `register` 依赖，并稍后在另一个文件中 `fetch` 它们。

我们来创建一个新文件 `di.jsx` ，它的代码如下所示:

```js
var dependencies = {};

export function register(key, dependency) {
  dependencies[key] = dependency;
}

export function fetch(key) {
  if (dependencies[key]) return dependencies[key];
  throw new Error(`"${ key } is not registered as dependency.`);
}

export function wire(Component, deps, mapper) {
  return class Injector extends React.Component {
    constructor(props) {
      super(props);
      this._resolvedDependencies = mapper(...deps.map(fetch));
    }
    render() {
      return (
        <Component
          {...this.state}
          {...this.props}
          {...this._resolvedDependencies}
        />
      );
    }
  };
}
```

我们将依赖保存在了 `dependencies` 这个全局变量中 (对于模块它是全局的，但对于整个应用来是并不是) 。然后，我们导出 `register` 和 `fetch` 这两个函数，它们负责读写依赖关系的数据。它看起来有点像对简单的 JavaScript 对象实现的 setter 和 getter 。再然后是 `wire` 函数，它接收 React 组件并返回 [高阶组件](../chapter-4/README.md#%E9%AB%98%E9%98%B6%E7%BB%84%E4%BB%B6) 。在组件的构造函数中，我们解析了依赖，并在稍后渲染原始组件时将其作为属性传给组件。我们按照相同的模式来描述我们需要的东西 (`deps` 参数)，并使用  `mapper` 函数来提取所需属性。

有了 `di.jsx` 辅助函数，我们又能够在应用的入口点 ( `app.jsx` ) 注册依赖，并且在任意组件 ( `Title.jsx` ) 中进行注入。

<span class="new-page"></span>

```js
// app.jsx
import Header from './Header.jsx';
import { register } from './di.jsx';

register('my-awesome-title', 'React in patterns');

class App extends React.Component {
  render() {
    return <Header />;
  }
};

// -----------------------------------
// Header.jsx
import Title from './Title.jsx';

export default function Header() {
  return (
    <header>
      <Title />
    </header>
  );
}

// -----------------------------------
// Title.jsx
import { wire } from './di.jsx';

var Title = function(props) {
  return <h1>{ props.title }</h1>;
};

export default wire(
  Title,
  ['my-awesome-title'],
  title => ({ title })
);
```

*如果查看 `Title.jsx` 文件的话，可以看到实际的组件和 `wire` 存在于不同的文件中。这种方式让组件和 mapper 函数的单元测试更简单。*

## 结语

依赖注入是一个大问题，尤其是在 JavaScript 中。许多人并没有意识到，但是，正确的依赖管理是每个开发周期中的关键过程。JavaScript 生态提供了不同的工具，作为开发者的我们应该挑选最适合自己的工具。
