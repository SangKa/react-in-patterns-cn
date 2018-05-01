# 单向数据流

单向数据流这种模式十分适合跟 React 搭配使用。它的主要思想是组件不会改变接收的数据。它们只会监听数据的变化，当数据发生变化时它们会使用接收到的新值，而不是去修改已有的值。当组件的更新机制触发后，它们只是使用新值进行重新渲染而已。

假设说有一个简单的 `Switcher` 组件，它包含一个按钮。当点击按钮时，我们需要在组件中使用一个标识来保存组件的开关状态。

```js
class Switcher extends React.Component {
  constructor(props) {
    super(props);
    this.state = { flag: false };
    this._onButtonClick = e => this.setState({
      flag: !this.state.flag
    });
  }
  render() {
    return (
      <button onClick={ this._onButtonClick }>
        { this.state.flag ? 'lights on' : 'lights off' }
      </button>
    );
  }
};

// ... 渲染组件
function App() {
  return <Switcher />;
};
```

此时，我们将数据保存在了组件内部。或者换句话说，知道 `flag` 存在的只有 `Switcher` 组件。我们来将 `flag` 提取到 store 中:

```js
var Store = {
  _flag: false,
  set: function(value) {
    this._flag = value;
  },
  get: function() {
    return this._flag;
  }
};

class Switcher extends React.Component {
  constructor(props) {
    super(props);
    this.state = { flag: false };
    this._onButtonClick = e => {
      this.setState({ flag: !this.state.flag }, () => {
        this.props.onChange(this.state.flag);
      });
    }
  }
  render() {
    return (
      <button onClick={ this._onButtonClick }>
        { this.state.flag ? 'lights on' : 'lights off' }
      </button>
    );
  }
};

function App() {
  return <Switcher onChange={ Store.set.bind(Store) } />;
};
```

`Store` 对象是一个 [单例](https://addyosmani.com/resources/essentialjsdesignpatterns/book/#singletonpatternjavascript)，它提供辅助函数 ( getter 和 setter ) 来读取/设置 `_flag` 属性。通过将 setter 传给 `Switcher` 组件，我们能够更新外部数据。目前我们应用的工作流程大致如下:

![one-direction data flow](./one-direction-1.jpg)

假设我们可以通过 `Store` 将 `flag` 值保存至服务端。当用户再使用时我们可以为其提供一个适当的初始值。如果用户上次离开时 `flag` 为 `true` ，那么我们应该显示 *"lights on"*，而不是默认值 *"lights off"* 。现在变得有一些麻烦，因为数据存在于两个地方。UI 和 `Store` 中都有自身的状态。我们需要进行双向通讯，`Store` 到组件和组件到 `Store` 。

```js
// ... 在 App 组件中
<Switcher
  value={ Store.get() }
  onChange={ Store.set.bind(Store) } />

// ... 在 Switcher 组件中
constructor(props) {
  super(props);
  this.state = { flag: this.props.value };
  ...
```

工作流程改变后如下所示:

![one-direction data flow](./one-direction-2.jpg)

以上这些导致了需要在两处管理状态。如果 `Store` 可以再根据系统中的其他操作更改其值，将演变成怎样一种情况？我们必须将这种变化传播给 `Switcher` 组件，这样就会增加应用的复杂度。

单向数据流正是用来解决此类问题。它消除了在多个地方同时管理状态的情况，它只会在一个地方 (通常就是 store) 进行状态管理。要实现单向数据流的话，我们需要改造一下 `Store` 对象。我们需要允许我们订阅数据变化的逻辑：

<span class="new-page"></span>

```js
var Store = {
  _handlers: [],
  _flag: '',
  subscribe: function(handler) {
    this._handlers.push(handler);
  },
  set: function(value) {
    this._flag = value;
    this._handlers.forEach(handler => handler(value))
  },
  get: function() {
    return this._flag;
  }
};
```

然后我们将其与 `App` 组件联系起来，每次 `Store` 中的值产生变化时，都将重新渲染组件:

```js
class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = { value: Store.get() };
    Store.subscribe(value => this.setState({ value }));
  }
  render() {
    return (
      <div>
        <Switcher
          value={ this.state.value }
          onChange={ Store.set.bind(Store) } />
      </div>
    );
  }
};
```

做出改变后，`Switcher` 将变得相当简单。我们不需要内部状态，所以组件可以使用无状态函数。

```js
function Switcher({ value, onChange }) {
  return (
    <button onClick={ e => onChange(!value) }>
      { value ? 'lights on' : 'lights off' }
    </button>
  );
};

<Switcher
  value={ Store.get() }
  onChange={ Store.set.bind(Store) } />
```

## 结语

这种模式的好处是组件只负责展示 store 的数据即可。而唯一的数据源将使得开发更加简单。如果只能从本书中掌握一个知识点的话，我会选这一章节。单向数据流彻底地改变了我设计功能时的思维方式，所以我相信对你也同样有效。
