# Flux

我痴迷于将代码变得简单。注意，我说的不是代码量*更少*，而是*简单*。因为代码量更少并不一定意味着简单。我相信软件行业中大部分问题都源自不必要的复杂度。复杂度是我们进行抽象的结果。你也知道，我们 (程序员) 都喜欢进行抽象。我们喜欢将抽象的东西放入黑盒中，并希望这些黑盒能够在一起工作。

[Flux](http://facebook.github.io/flux/) 是一种构建用户界面的架构设计模式。它是由 Facebook 在它们的 [F8](https://youtu.be/nYkdrAPrdcw?t=568) 开发者大会上推出的。在此之后，许多公司都采纳了这个想法，这种模式用来构建前端应用似乎非常不错。Flux 通常和 [React](http://facebook.github.io/react/) 搭配使用。React 是 Facebook 发布的另外一个库。我个人在 [日常工作](http://antidote.me/) 中使用的是 React+Flux/Redux ，并且我敢说这种架构真的非常简单和灵活。该模式有助于更快地创建应用，同时使代码保持良好的组织结构。

## Flux 架构及其主要特点

![Basic flux architecture](./fluxiny_basic_flux_architecture.jpg)

这种模式的主角是 *dispatcher* 。它担当系统中所有事件的枢纽。它的工作就是接收我们称之为 *actions* (动作) 的通知并将其传给所有的 *stores* 。store 决定了是否对传入的动作感兴趣，如果感兴趣则通过改变自己的内部状态/数据来进行响应。改变会触发 *views* (视图，这里指 React 组件) 的重新渲染。如果非要将 Flux 和大名鼎鼎的 MVC 相比较的话，Flux 中的 store 类似于 MVC 中的 model 。它负责保存和修改数据。

传给 dispatcher 的动作可以来自于视图，也可以来自于系统的其他部分，比如 services 。举个例子，一个执行 HTTP 请求的模块，当它接收到结果数据时，它可以触发动作以通知系统请求成功。

## 实现 Flux 架构

如其他流行的概念一样，Flux 也有一些 [变种](https://medium.com/social-tables-tech/we-compared-13-top-flux-implementations-you-won-t-believe-who-came-out-on-top-1063db32fe73) 。通常，要理解某种技术的最好途径就是去实现它。在下面的几节中，我们将创建一个库，它提供辅助函数来构建 Flux 模式。

### Dispatcher

大多数场景下，我们只需要一个单个的 dispatcher 。因为它扮演胶水的角色，用来粘合其他部分，所以有一个就够了。dispatcher 需要知道两样东西: 动作和 stores 。动作只是简单地转发给 stores，所以没必要保存它们。然而，stores 应该在 dispatcher 中进行追踪，这样才可以遍历它们: 

![the dispatcher](./fluxiny_the_dispatcher.jpg)

我开始是这样写的:

```js
var Dispatcher = function () {
  return {
    _stores: [],
    register: function (store) {  
      this._stores.push({ store: store });
    },
    dispatch: function (action) {
      if (this._stores.length > 0) {
        this._stores.forEach(function (entry) {
          entry.store.update(action);
        });
      }
    }
  }
};
```

首先需要注意的是我们*期望*传入的 stores 上存在 `update` 方法。如果此方法不存在的话，抛出错误会更好些:

```js
register: function (store) {
  if (!store || !store.update) {
    throw new Error('You should provide a store that has an `update` method.');
  } else {
    this._stores.push({ store: store });
  }
}
```

<br />

### 将视图和 stores 进行绑定

下一步是将视图与 stores 链接，这样当 stores 的状态发生改变时，我们才能进行重新渲染。

![Bounding the views and the stores](./fluxiny_store_change_view.jpg)

#### 使用辅助函数

一些 flux 的实现会自带辅助函数来完成此工作。例如:

```js
Framework.attachToStore(view, store);
```

然而，我并不怎么喜欢这种方式。要让 `attachToStore` 正常运行，需要视图和 store 中有一个特殊的 API ，因此我们需要严格定义这个新的公有方法。或者换句话说，Framework 对你说道: “你的视图和 store 应该具备这样的 API ，这样我才能能够将它们连接起来”。如果我们沿着这个方向前进的话，那么我们可能会定义可扩展的基类，这样我们就不会让 Flux 的细节去困扰开发人员。然后，Framework 又对你说到: “你所有的类都应该继承我们的类”。这听上去也并非好主意，因为开发人员可能会切换成另一个 Flux 提供者，这种切换势必会修改所有内容。

<br /><br />

#### 使用 mixin

那么如果使用 React 的 [mixins](https://facebook.github.io/react/docs/reusable-components.html#mixins) 呢？

```js
var View = React.createClass({
  mixins: [Framework.attachToStore(store)]
  ...
});
```

为已存在的 React 组件定义行为的话，这是一种“更好的”方式。所以，从理论上来说，我们可能会创建 mixin 来完成绑定工作。但说实话，我并认为这是个好主意。[看起来](https://medium.com/@dan_abramov/mixins-are-dead-long-live-higher-order-components-94a0d2f9e750) 不止我一个人有这种想法。我不喜欢 mixins 的原因是它们修改组件的方式是不可预见的。我完全不知道幕后发生了什么。所以我放弃这个选项。

#### 使用 context

解决此问题的另一项技术便是 React 的 [context](https://facebook.github.io/react/docs/context.html) 。使用 context 可以将 props 传递给子组件而无需在组件树中进行层层传递。Facebook 建议在数据必须到达嵌套层级非常深的组件的情况下使用 context 。

> 偶尔，你希望通过组件树传递数据，而不必在每个级别手动传递这些 props 。React 的 "context" 功能可以让你做到这一点。

我看到了与 mixins 的相似之处。context 是在组件树的顶层定义的，并魔法般的为组件树中的所有的子组件提供 props 。至于数据从而何来，尚不可知。

<br /><br /><br />

#### 高阶组件概念

高阶组件模式是由 Sebastian Markb&#229;ge 所[提出](https://gist.github.com/sebmarkbage/ef0bf1f338a7182b6775)的。它创建一个包装组件并返回原始的输入组件。使用高阶组件的话，就有机会来传递属性或应用附加逻辑。例如:

```js
function attachToStore(Component, store, consumer) {
  const Wrapper = React.createClass({
    getInitialState() {
      return consumer(this.props, store);
    },
    componentDidMount() {
      store.onChangeEvent(this._handleStoreChange);
    },
    componentWillUnmount() {
      store.offChangeEvent(this._handleStoreChange);
    },
    _handleStoreChange() {
      if (this.isMounted()) {
        this.setState(consumer(this.props, store));
      }
    },
    render() {
      return <Component {...this.props} {...this.state} />;
    }
  });
  return Wrapper;
};
```

`Component` 是我们想要附加到 `store` 中的视图。`consumer` 函数说明应该提取 store 的哪部分状态并发送给到视图。上面函数的简单用法如下所示:

```js
class MyView extends React.Component {
  ...
}

ProfilePage = connectToStores(MyView, store, (props, store) => ({
  data: store.get('key')
}));

```

这是个有趣的模式，因为它转移了职责。它是视图从 store 中拉取数据，而不是 store 将数据推送给视图。当然它也有自己的优势和劣势。优势在于它使得 store 变得简单。现在 store 只修改数据即可，并告诉大家: “嗨，我的状态发生改变了”。它不再负责将数据发送给别人。这种方法的缺点可能是我们将有不止一个组件 (包装组件) 参与其中。我们还需要视图、store 和 consumer 函数三者在同一个地方，这样我们才可以建立连接。

#### 我的选择

我的选择是最后一个选项 - 高阶组件，它已经非常接近于我想要的。我喜欢由视图来决定它所需要什么的这点。无论如何，*数据*都存在于组件中，所以将它保留在那里是有道理的。这也正是为什么生成高阶组件的函数通常与视图保持在同一个文件中的原因。如果我们使用类似的方法而压根不传入 store 呢？或者换句话说，函数只接收 consumer 。每当 store 发生变化时，都会调用此函数。

目前为止，我们的实现中只有 `register` 方法与 store 进行交互。

```js
register: function (store) {
  if (!store || !store.update) {
    throw new Error('You should provide a store that has an `update` method.');
  } else {
    this._stores.push({ store: store });
  }
}
```

通过使用 `register`，我们在 dispatcher 内部保存了 store 的引用。但是，`register` 不返回任何东西。或许，我们可以返回一个 **subscriber** (订阅者) 来接收 consumer 函数。

![Fluxiny - connect store and view](./fluxiny_store_view.jpg)

我决定将整个 store 发送给 consumer 函数，而不是 store 中的保存的数据。就像在高阶组件模式中一样，视图应该使用 store 的 getter 来说明它需要什么。这使得 store 变得相当简单并且不包含任何表现层相关的逻辑。

下面是更改后的 `register` 方法:

```js
register: function (store) {
  if (!store || !store.update) {
    throw new Error(
      'You should provide a store that has an `update` method.'
    );
  } else {
    var consumers = [];
    var subscribe = function (consumer) {
      consumers.push(consumer);
    };

    this._stores.push({ store: store });
    return subscribe;
  }
  return false;
}
```

最后要完成是 store 如何通知别人它内部的状态发生了改变。我们已经收集了 consumer 函数，但现在还没有任何代码来执行它们。

根据 flux 架构的基本原则，stores 改变自身状态以响应动作。在 `update` 方法中，我们发送了 `action`，但我们还应该发出 `change` 函数。调用此函数来触发 consumers :

```js
register: function (store) {
  if (!store || !store.update) {
    throw new Error(
      'You should provide a store that has an `update` method.'
    );
  } else {
    var consumers = [];
    var change = function () {
      consumers.forEach(function (consumer) {
        consumer(store);
      });
    };
    var subscribe = function (consumer) {
      consumers.push(consumer);
    };

    this._stores.push({ store: store, change: change });
    return subscribe;
  }
  return false;
},
dispatch: function (action) {
  if (this._stores.length > 0) {
    this._stores.forEach(function (entry) {
      entry.store.update(action, entry.change);
    });
  }
}
```

*注意如何在 `_stores` 数组中将 `change` 和 `store` 一起推送出去。稍后，在 `dispatch` 方法中通过传入 `action` 和 `change` 函数来调用 `update` *

常见用法是使用 store 的初始状态来渲染视图。在我们实现中，这意味着当库被使用时至少触发所有 consumer 函数一次。这可以在 `subscribe` 方法中轻松完成:

```js
var subscribe = function (consumer, noInit) {
  consumers.push(consumer);
  !noInit ? consumer(store) : null;
};
```

当然，有时候并不需要，所以我们添加了一个标识，它的默认值是假值。下面是 dispatcher 的最终版本:

<span class="new-page"></span>

```js
var Dispatcher = function () {
  return {
    _stores: [],
    register: function (store) {
      if (!store || !store.update) {
        throw new Error(
          'You should provide a store that has an `update` method'
        );
      } else {
        var consumers = [];
        var change = function () {
          consumers.forEach(function (consumer) {
            consumer(store);
          });
        };
        var subscribe = function (consumer, noInit) {
          consumers.push(consumer);
          !noInit ? consumer(store) : null;
        };

        this._stores.push({ store: store, change: change });
        return subscribe;
      }
      return false;
    },
    dispatch: function (action) {
      if (this._stores.length > 0) {
        this._stores.forEach(function (entry) {
          entry.store.update(action, entry.change);
        });
      }
    }
  }
};
```

<span class="new-page"></span>

## 动作 ( Actions )

你或许已经注意到了，我们还没讨论过动作。什么是动作？约定是它们应该是具有两个属性的简单对象: `type` 和 `payload` ：

```js
{
  type: 'USER_LOGIN_REQUEST',
  payload: {
    username: '...',
    password: '...'
  }
}
```

`type` 表明了这个动作具体是做什么的，`payload` 包含事件的相关信息，而且它并非是必需的。

有趣的是 `type` 从一开始就广为人知。我们知道什么类型的动作应该进入应用，谁来分发它们，已经 stores 对哪些动作感兴趣。因此，我们可以应用 [partial application](http://krasimirtsonev.com/blog/article/a-story-about-currying-bind) 并避免传入动作对象。例如:

```js
var createAction = function (type) {
  if (!type) {
    throw new Error('Please, provide action\'s type.');
  } else {
    return function (payload) {
      return dispatcher.dispatch({
        type: type,
        payload: payload
      });
    }
  }
}
```

`createAction` 具有以下优点:

* 我们不再需要记住动作的具体类型是什么。现在只需传入 payload 来调用此函数即可。
* 我们不再需要访问 dispatcher 了，这是个巨大的优势。否则，还需要考虑如何将它传递给每个需要分发动作的地方。
* 最后，我们不用再去处理对象，只是调用函数，这种方式要好得多。对象是*静态的*，而函数描述的是*过程*。

![Fluxiny actions creators](./fluxiny_action_creator.jpg)

这种创建动作的方式非常流行，像上面这样的函数我们称之为 “action creators” 。

## 最终代码

在上一节中，在我们发出动作的同时隐藏了 dispatcher 。在 store 的注册过程中我们也可以这样做:

```js
var createSubscriber = function (store) {
  return dispatcher.register(store);
}
```

我们可以不暴露 dispaatcher，而只暴露 `createAction` 和 `createSubscriber` 这两个函数。下面是最终代码:

```js
var Dispatcher = function () {
  return {
    _stores: [],
    register: function (store) {
      if (!store || !store.update) {
        throw new Error(
          'You should provide a store that has an `update` method'
        );
      } else {
        var consumers = [];
        var change = function () {
          consumers.forEach(function (consumer) {
            consumer(store);
          });
        };
        var subscribe = function (consumer, noInit) {
          consumers.push(consumer);
          !noInit ? consumer(store) : null;
        };

        this._stores.push({ store: store, change: change });
        return subscribe;
      }
      return false;
    },
    dispatch: function (action) {
      if (this._stores.length > 0) {
        this._stores.forEach(function (entry) {
          entry.store.update(action, entry.change);
        });
      }
    }
  }
};

module.exports = {
  create: function () {
    var dispatcher = Dispatcher();

    return {
      createAction: function (type) {
        if (!type) {
          throw new Error('Please, provide action\'s type.');
        } else {
          return function (payload) {
            return dispatcher.dispatch({
              type: type,
              payload: payload
            });
          }
        }
      },
      createSubscriber: function (store) {
        return dispatcher.register(store);
      }
    }
  }
};

```

如果添加对 AMD、CommonJS 和全局引用的支持的话，那么最终的 JavaScript 文件共 66 行代码，文件大小为 1.7KB，压缩后 795 字节。

## 整合

我们写好的模块提供两个辅助函数来构建 Flux 项目。我们来写个简单的计数器应用，此应用不使用 React ，只为了解 Flux 模式的实际使用情况。

<span class="new-page"></span>

### HTML

我们需要一些 UI 元素来进行互动:

```html
<div id="counter">
  <span></span>
  <button>increase</button>
  <button>decrease</button>
</div>
```

`span` 用来显示计数器的当前值。点击按钮会改变计数器的值。

### 视图

```js
const View = function (subscribeToStore, increase, decrease) {
  var value = null;
  var el = document.querySelector('#counter');
  var display = el.querySelector('span');
  var [ increaseBtn, decreaseBtn ] =
    Array.from(el.querySelectorAll('button'));

  var render = () => display.innerHTML = value;
  var updateState = (store) => value = store.getValue();

  subscribeToStore([updateState, render]);

  increaseBtn.addEventListener('click', increase);
  decreaseBtn.addEventListener('click', decrease);
};
```

View 接收 store 的订阅者函数和增加/减少值的两个动作函数。View 中开始的几行代码只是用来获取 DOM 元素。

之后我们定义了 `render` 函数，它负责将值渲染到 `span` 标签中。当 store 发生变化时会调用 `updateState` 方法。我们将这两个函数传给 `subscribeToStore` 是因为我们想要视图更新以及进行初首次渲染。还记得 consumers 函数默认至少要调用一次吧？

最后要做的是为按钮绑定点击事件。

### Store

每个动作都有类型。为这些类型创建常量是一种最佳实践，因为我们不想处理原始字符串。

```js
const INCREASE = 'INCREASE';
const DECREASE = 'DECREASE';
```

通常每个 store 只有一个实例。为了简单起见，我们将直接创建一个单例对象。

```js
const CounterStore = {
  _data: { value: 0 },
  getValue: function () {
    return this._data.value;
  },
  update: function (action, change) {
    if (action.type === INCREASE) {
      this._data.value += 1;
    } else if (action.type === DECREASE) {
      this._data.value -= 1;
    }
    change();
  }
};
```

`_data` 是 store 的内部状态。`update` 是 dispatcher 所调用的方法，我们在 `update` 中处理动作，并在完成时调用 `change()` 方法来通知发生了变化。`getValue` 是公共方法，视图会使用它来获取所需数据。(在这个案例中，就是计数器的值。)

### 整合各个部分

这样，store 就完成了，它等待 dispatcher 发出的动作。视图我们也定义完了。现在来创建 store 的订阅者、动作并让这一切运转起来。

```js
const { createAction, createSubscriber } = Fluxiny.create();
const counterStoreSubscriber = createSubscriber(CounterStore);
const actions = {
  increase: createAction(INCREASE),
  decrease: createAction(DECREASE)
};

View(counterStoreSubscriber, actions.increase, actions.decrease);
```

这样就完成了。视图订阅 store 并进行渲染，因为我们的 consumers 实际上就是 `render` 方法。

### 在线示例

这里有 JSBin 的 [在线示例](http://jsbin.com/koxidu/embed?js,output)。如果你觉得这个示例过于简单的话，请查阅 [Fluxiny 仓库中的示例](https://github.com/krasimir/fluxiny/tree/master/example)。它使用 React 作为视图层。

*在本章中所讨论的 Flux 实现可以在 [这里](https://github.com/krasimir/fluxiny) 找到。可以 [直接在浏览器中](https://github.com/krasimir/fluxiny/tree/master/lib) 使用，也可以通过 [npm 依赖](https://www.npmjs.com/package/fluxiny) 进行安装。*
