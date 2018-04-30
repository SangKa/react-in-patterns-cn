# 受控输入和非受控输入

在 React 表单管理中有两个经常使用的术语: *受控输入*和*非受控输入*。*受控收入*是指输入值的来源是单一的。例如，下面的 `App` 组件有一个 `<input>` 字段，它就是*受控的*:

```js
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { value: 'hello' };
  }
  render() {
    return <input type='text' value={ this.state.value } />;
  }
};
```

上面代码的结果是我们可以操作 input 元素，但是无法改变它的值。它永远都不会更新，因为我们使用的是单一数据源: `App` 组件的状态。要想让 input 正常工作的话，需要为其添加 `onChange` 处理方法来更新状态 (单一数据源)。`onChange` 会触发新的渲染周期，所以能看到在 input 中输入的文字。

<span class="new-page"></span>

```js
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { value: 'hello' };
    this._change = this._handleInputChange.bind(this);
  }
  render() {
    return (
      <input
        type='text'
        value={ this.state.value }
        onChange={ this._change } />
    );
  }
  _handleInputChange(e) {
    this.setState({ value: e.target.value });
  }
};
```

与之相反的是*非受控输入*，它让浏览器来处理用户的输入。我们还可以通过使用 `defaultValue` 属性来提供初始值，此后浏览器将负责保存输入的状态。

```js
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { value: 'hello' };
  }
  render() {
    return <input type='text' defaultValue={ this.state.value } />
  }
};
```

上面的 `<input>` 元素其实没什么用，因为我们的组件并不知道用户更新的值。我们需要使用 [`Refs`](https://reactjs.org/docs/glossary.html#refs) 来获取 DOM 元素的实际引用。

```js
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { value: 'hello' };
    this._change = this._handleInputChange.bind(this);
  }
  render() {
    return (
      <input
        type='text'
        defaultValue={ this.state.value }
        onChange={ this._change }
        ref={ input => this.input = input }/>
    );
  }
  _handleInputChange() {
    this.setState({ value: this.input.value });
  }
};
```

`ref` 属性接收字符串或回调函数。上面的代码使用回调函数来将 DOM 元素保存在*局部*变量 `input` 中。之后当 `onChange` 事件触发时，我们将 input 中的最新值保存到 `App` 组件的状态里。

*大量使用 `refs` 并非是个好主意。如果你的应用中出现了这种情况的话，那么你需要考虑使用受控输入并重新审视组件。*

## 结语

使用*受控输入*还是*非受控输入*，这个选择常常不被人所重视。但我相信这是一个最基本的决策，因为它决定了 React 组件的数据流。我个人认为*非受控输入*更像是一种反模式，应该尽量避免使用。


