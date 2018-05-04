# Redux

[Redux](https://redux.js.org/) 是一个库，它扮演着状态容器的角色，并负责管理应用的数据流。它是 [Dan Abramov](https://twitter.com/dan_abramov) 在 2015 年的 ReactEurope 开发者大会上推出的 ([视频](https://www.youtube.com/watch?v=xsSnOQynTHs))。它类似于 [Flux 架构](https://github.com/krasimir/react-in-patterns/blob/master/book/chapter-8/README.md#flux-architecture-and-its-main-characteristics) 并有很多共同点。在本章中，我们将使用 Redux 和 React 来创建一个小型的计数器应用。

<span class="new-page"></span>

## Redux 架构及其主要特点

![Redux architecture](./redux-architecture.jpg)

类似于 [Flux](https://github.com/krasimir/react-in-patterns/blob/master/book/chapter-8/README.md) 架构，由视图组件 (React) 来派发动作。同一个动作也可能是由系统的其他部分派发的，例如引导逻辑。动作不是派发到中心枢纽中，而是直接派发到 `store` 中。注意，我们说的是 `store`，而不是 `stores` ，这是因为在 Redux 中只有一个 store ，这是 Redux 与 Flux 的最重要的区别之一。决定数据如何改变的逻辑以纯函数 ( pure functions ) 的形式存在，我们称之为 `reducers` 。一旦 store 接收到动作，它会将当前状态和给定动作发送给 reducer 并要求其返回一个新的状态。然后，在数据不可变的方式下， reducer 需要返回新的状态。再然后， store 更新自身的内部状态。最后，与 store 连接的 React 组件会重新渲染。

概念相当清晰并再次遵循了 [单向数据流](https://github.com/krasimir/react-in-patterns/blob/master/book/chapter-7/README.md) 。我们来讨论每一个部分并引入一些支持 Redux 模式工作的新术语。

### 动作 ( Actions )

Redux 中的动作和 Flux 一样，也只是有 `type` 属性的对象而已。该对象中的其他所有内容都被视为特定于上下文的数据，并且与模式无关，而与应用的逻辑相关。例如:

```js
const CHANGE_VISIBILITY = 'CHANGE_VISIBILITY';
const action = {
  type: CHANGE_VISIBILITY,
  visible: false
}
```

使用像 `CHANGE_VISIBILITY` 这样的常量作为动作的类型是一种最佳实践。有很多支持 Redux 的工具和库，它们用来解决不用的问题，并且都只需要动作的类型即可。所以说，动作只是传递信息的一种便捷方式。

`visible` 属性是我们所提到过的元数据。它与 Redux 本身无关，它表示应用中某处需要使用的数据。

每次我们想要派发动作时都需要使用这样的对象。但是，一遍又一遍地写确实是让太人烦躁了。这也正是概念 *action creators* 诞生的原因。action creator 是返回动作对象的函数，它可选项性地接收与动作相关联的属性。例如，如果将上面的 action 写成 action creator 会是这样:

```js
const changeVisibility = visible => ({
  type: CHANGE_VISIBILITY,
  visible
});

changeVisibility(false);
// { type: CHANGE_VISIBILITY, visible: false }
```

注意，我们将 `visible` 的值作为参数传入，这样我们不必去记住 (或导入) 动作的确切类型。使用这种辅助函数可以让代码更紧凑，更易于阅读。

### Store

Redux 提供辅助函数 `createStore` 来创建 store 。它的函数签名如下:

```js
import { createStore } from 'redux';

createStore([reducer], [initial state], [enhancer]);
```

正如之前所提到的，reducer 是一个函数，它接收当前状态和动作，然后返回一个新的状态。第二个参数是 store 的初始状态。这是一种便捷的手段，可以用已有的数据来初始化我们的应用。这个功能是像服务器端渲染或持久体验这样的过程的本质。第三个参数 enhancer 提供 API 来使用第三方的中间件来扩展 Redux ，基本上是插入一些自身没有提供的功能，例如处理异步流程的工具。

创建好的 store 具有四个方法: `getState`、`dispatch`、`subscribe` 和 `replaceReducer` 。其中最重要的或许就是 `dispatch` :

```js
store.dispatch(changeVisibility(false));
```

这里我们使用的是 action creator 。我们将其结果 (即 action 对象) 传给 `dispatch` 方法。然后，它会传播给应用中的 reducers 。

在典型的 React 应用中，我们通常不会直接使用 `getState` 和 `subscribe` ，因为有辅助函数 (即将在后面的章节中讲到) 可以将组件和 store 联系起来并有效地订阅 store 的变化。作为订阅的一部分，我们自然可以收到当前的状态，所以不必自己去调用 `getState` 。`replaceReducer` 是一个高级 API ，它用来交互 store 所使用的当前 reducer 。我个人从来没使用过此方法。

### Reducer

reducer 函数大概是 Redux 中最*精华*的部分。即使在此之前，我也喜欢编写纯函数来保持这种不可变的思想，但是 Redux 迫使我这样做。reducer 还有两个特点非常重要，没有它们的话基本上这种模式也不复存在。

(1) 它必须是纯函数 - 这意味着在输入不变的情况下，永远应该返回相同的结果。

(2) 它应该没有副作用 - 像访问全局变量、发起异步请求或等待 promise 解析这样的操作都不应该用在此处。

下面是个很简单的计数器 reducer :

```js
const counterReducer = function (state, action) {
  if (action.type === ADD) {
    return { value: state.value + 1 };
  } else if (action.type === SUBTRACT) {
    return { value: state.value - 1 };
  }
  return { value: 0 };
};
```

它没有任何副作用，每次都是返回一个全新的对象。我们根据之前的状态和传入的动作类型来累加出新的值。

### 连接 React 组件

如果是在 React 上下文中讨论 Redux 的话，那基本离不开 [react-redux](https://github.com/reactjs/react-redux) 模块。它提供两样东西来进行 Redux 到组件的连接。

(1) `<Provider>` 组件 - 它是一个组件，它接收 store 并使得所有的子组件都可以通过 React 的 context API 来访问 store 。例如:

```js
<Provider store={ myStore }>
  <MyApp />
</Provider>
```

通常，我们只在应用中的单个地方使用它。

(2) `connect` 函数 - 它是一个函数，它负责订阅 store 的更新和重新渲染组件。它是通过 [高阶组件](https://github.com/krasimir/react-in-patterns/blob/master/book/chapter-4/README.md#higher-order-component) 实现的。这是它的函数签名:

```
connect(
  [mapStateToProps],
  [mapDispatchToProps],
  [mergeProps],
  [options]
)
```

`mapStateToProps` 参数是一个函数，它接收 store 的当前状态，并且必须返回一组键值对 (对象)，这些对将作为 props 发送给我们的 React 组件。例如:

```js
const mapStateToProps = state => ({
  visible: state.visible
});
```

`mapDispatchToProps` 也是类似的，只是它接收的是 `dispatch` 函数，而不是 `state` 。这里是我们将派发动作定义成属性的地方。

```js
const mapDispatchToProps = dispatch => ({
  changeVisibility: value => dispatch(changeVisibility(value))
});
```

`mergeProps` 将 `mapStateToProps`、 `mapDispatchToProps` 和发送给组件的属性进行合并，它赋予我们机会去累加出更适合的属性。例如，如果我们需要触发两个动作，我们可以将它们组合成一个单独的属性并将其发送给 React 。`options` 接收一组如何控制连接的设置。

<br />

## 使用 Redux 的简单计数器应用

我们来使用上面所有的 API 来创建一个简单的计数器应用。

![Redux counter app example](./redux-counter-app.png)

"Add" 和 "Subtract" 按钮只是改变 store 的值。"Visible" 和 "Hidden" 按钮用来控制计数器是否显示。

### 创建动作

对我来说，每个 Redux 的开始都是对动作类型建模及定义我们所要保存的状态。在这个示例中，我们会有三个操作: 增加、减少和管理可见性。所有动作代码如下所示:

```js
const ADD = 'ADD';
const SUBTRACT = 'SUBTRACT';
const CHANGE_VISIBILITY = 'CHANGE_VISIBILITY';

const add = () => ({ type: ADD });
const subtract = () => ({ type: SUBTRACT });
const changeVisibility = visible => ({
  type: CHANGE_VISIBILITY,
  visible
});
```

### Store 及其 reducers

我们在解释 store 和 reudcers 时，有些技术点是没有讨论到的。通常，我们会有多个 reducer ，因为要管理多种状态。store 只有一个，所以理论上只有一个状态对象。但是大多数生产环境的应用的状态都是状态切片的组合。每个切片代表应用的一部分。这个小示例拥有计数和可见性两个切片。所以我们的初始状态应该是这样的:

```js
const initialState = {
  counter: {
    value: 0
  },
  visible: true
};
```

我们需要为这两部分分别定义 reducer 。这样会带来灵活性并提升代码的可读性。想象一下，如果我们有一个拥有十个或更多状态切片的巨型应用，并且我们只使用单个 reducer 函数来进行维护，这样管理起来将会非常困难。

Redux 提供辅助函数来让我们能够锁定 state 的某个特定部分并为其分配一个 reducer 。它就是 `combineReducers` :

```js
import { createStore, combineReducers } from 'redux';

const rootReducer = combineReducers({
  counter: function A() { ... },
  visible: function B() { ... }
});
const store = createStore(rootReducer);
```

函数 `A` 只接收 `counter` 切片作为状态，并且只返回切片这部分的状态。函数 `B` 也是同样的，它接收布尔值 (`visible` 的值) 并且必须返回布尔值。

`counter` 切片的 reducer 应该考虑到 `ADD` 和 `SUBTRACT` 两个动作，并基于动作来计算出新的 `counter` 状态。

```js
const counterReducer = function (state, action) {
  if (action.type === ADD) {
    return { value: state.value + 1 };
  } else if (action.type === SUBTRACT) {
    return { value: state.value - 1 };
  }
  return state || { value: 0 };
};
```

当 store 初始化时，每个 reducer 至少触发一次。最初运行的这一次，`state` 为 `undefined` ，`action` 为 `{ type: "@@redux/INIT"}` 。在这个实例中，reducer 应该返回数据的初始值 `{ value: 0 }` 。

`visible` 的 reducer 相当简单，它只处理动作 `CHANGE_VISIBILITY` :

```js
const visibilityReducer = function (state, action) {
  if (action.type === CHANGE_VISIBILITY) {
    return action.visible;
  }
  return true;
};
```

最后，我们需要将这两个 reducers 传给 `combineReducers` 来创建 `rootReducer` 。

```js
const rootReducer = combineReducers({
  counter: counterReducer,
  visible: visibilityReducer
});
```

### 选择器 ( Selectors )

在开始 React 组件之前，我们先介绍一个 *选择器 ( selector )* 的概念。在上一节中，我们知道状态通常都是细化成多个状态切片。我们有专门的 reducer 来负责更新数据，但是当涉及到获取状态数据时，我们仍然只是有一个对象。这里就是选择器派上用场的地方。选择器就是一个函数，它接收整个状态对象并提取出我们所需要的数据。例如，在这个小示例应用中我们需要两个数据:

```js
const getCounterValue = state => state.counter.value;
const getVisibility = state => state.visible;
```

这个计数器应用实在是太小了，完全体现不出选择器的威力。但是，在一个大项目中便截然不同。选择器的存在并不是为了少些几行代码，也不是为了可读性。选择器附带了这些内容，但它们也是上下文相关的，可能包含逻辑。由于它们可以访问整个状态，所以它们能够回答业务逻辑相关的问题。例如，“在 Y 页面用户是否有权限可以做 X 这件事”。这样的事通过一个选择器就可以完成。

### React 组件

我们先来处理管理计数器可见性的 UI 部分。

```js
function Visibility({ changeVisibility }) {
  return (
    <div>
      <button onClick={ () => changeVisibility(true) }>
        Visible
      </button>
      <button onClick={ () => changeVisibility(false) }>
        Hidden
      </button>
    </div>
  );
}

const VisibilityConnected = connect(
  null,
  dispatch => ({
    changeVisibility: value => dispatch(changeVisibility(value))
  })
)(Visibility);
```

第二个组件略微有些复杂。将它命名为 `Counter` ，它渲染两个按钮和计数值。

```js
function Counter({ value, add, subtract }) {
  return (
    <div>
      <p>Value: { value }</p>
      <button onClick={ add }>Add</button>
      <button onClick={ subtract }>Subtract</button>
    </div>
  );
}

const CounterConnected = connect(
  state => ({
    value: getCounterValue(state)
  }),
  dispatch => ({
    add: () => dispatch(add()),
    subtract: () => dispatch(subtract())
  })
)(Counter);
```

这里 `mapStateToProps` 和 `mapDispatchToProps` 都需要，因为我们想读取 store 中的数据，同时还要派发动作。这个组件要接收三个属性: `value`、`add` 和 `subtract` 。

最后要完成的就是 `App` 组件，我们在这里进行应用的组装。

```js
function App({ visible }) {
  return (
    <div>
      <VisibilityConnected />
      { visible && <CounterConnected /> }
    </div>
  );
}
const AppConnected = connect(
  state => ({
    visible: getVisibility(state)
  })
)(App);
```

我们再一次需要对组件进行 `connect` 操作，因为我们想要控制计数器的显示。`getVisibility` 选择器返回布尔值，它表示是否渲染 `CounterConnected` 组件。

## 结语

Redux 是一种很棒的模式。最近几年，JavaScript 社区将这种理念发扬下去，并使用一些新术语对其进行了增强。我认为一个典型的 Redux 应用应该是下面这样的:

![Redux architecture](redux-reallife.jpg)

*顺便一提，我们还没有介绍过副作用管理。那将是另外的新篇章了，它有自己的理念和解决方案。*

我们可以得出结论，Redux 本身是一种非常简单的模式。它传授了非常有用的技术，但不幸的是光靠它自身往往是不够的。我们迟早要引入更多的概念或模式。当然这没有那么糟糕，我们只是先提起计划一下。