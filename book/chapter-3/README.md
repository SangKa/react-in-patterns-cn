# 事件处理

对于事件处理，React 提供了一系列属性。解决方案几乎和使用标准化 DOM 完全一样。也有一些不同点，比如使用驼峰式或传入的是函数，但总体来说，还是十分相似的。

```js
const theLogoIsClicked = () => alert('Clicked');

<Logo onClick={ theLogoIsClicked } />
<input
  type='text'
  onChange={event => theInputIsChanged(event.target.value) } />
```

通常，我们在包含派发事件的元素的组件中处理事件。比如在下面的示例中，我们有一个事件处理函数，我们想要在同一个组件中运行函数或方法:

```js
class Switcher extends React.Component {
  render() {
    return (
      <button onClick={ this._handleButtonClick }>
        click me
      </button>
    );
  }
  _handleButtonClick() {
    console.log('Button is clicked');
  }
};
```

这样使用完全可以，因为 `_handleButtonClick` 是一个函数，而我们也确实将这个函数传给了 `onClick` 属性。问题是这段代码中并没有保持同一个上下文。所以，如果我们在 `_handleButtonClick` 函数中使用 `this` 来获取 `Switcher` 组件的引用时将会报错。

```js
class Switcher extends React.Component {
  constructor(props) {
    super(props);
    this.state = { name: 'React in patterns' };
  }
  render() {
    return (
      <button onClick={ this._handleButtonClick }>
        click me
      </button>
    );
  }
  _handleButtonClick() {
    console.log(`Button is clicked inside ${ this.state.name }`);
    // 导致
    // Uncaught TypeError: Cannot read property 'state' of null
  }
};
```

通常，我们使用 `bind` 来解决:

```js
<button onClick={ this._handleButtonClick.bind(this) }>
  click me
</button>
```

但是，这样做的话 `bind` 函数会一次又一次地被调用，这是因为 button 可能会渲染多次。一种更好的方式是在组件的构造函数中来创建绑定:

<span class="new-page"></span>

```js
class Switcher extends React.Component {
  constructor(props) {
    super(props);
    this.state = { name: 'React in patterns' };
    this._buttonClick = this._handleButtonClick.bind(this);
  }
  render() {
    return (
      <button onClick={ this._buttonClick }>
        click me
      </button>
    );
  }
  _handleButtonClick() {
    console.log(`Button is clicked inside ${ this.state.name }`);
  }
};
```

附带一提，在处理函数需要和组件的上下文保持统一时，Facebook [推荐](https://facebook.github.io/react/docs/reusable-components.html#no-autobinding) 的也是此技巧。

构造函数还是部分执行处理函数的好地方。例如，我们有一个表单，但是不想为每个 input 提供一个单独的处理函数。

<span class="new-page"></span>

```js
class Form extends React.Component {
  constructor(props) {
    super(props);
    this._onNameChanged = this._onFieldChange.bind(this, 'name');
    this._onPasswordChanged =
      this._onFieldChange.bind(this, 'password');
  }
  render() {
    return (
      <form>
        <input onChange={ this._onNameChanged } />
        <input onChange={ this._onPasswordChanged } />
      </form>
    );
  }
  _onFieldChange(field, event) {
    console.log(`${ field } changed to ${ event.target.value }`);
  }
};
```

## 结语

对于 React 中的事件处理，其实没有太多需要学习的。React 的作者们在保留开发者的使用习惯上做的十分出色。因为 JSX 使用的是类似 HTML 的语法，所以使用类似 DOM 的事件处理意义重大。
