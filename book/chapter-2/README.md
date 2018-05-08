# 组件通讯

每个 React 组件就像一个独立运行的小型系统。它有自己的状态、输入和输出。下面，我们将来探讨这些特性。

![Input-Output](./communication.jpg)

## 输入

React 组件的输入是它的 props 。它传递数据的方式如下所示:

```js
// Title.jsx
function Title(props) {
  return <h1>{ props.text }</h1>;
}
Title.propTypes = {
  text: PropTypes.string
};
Title.defaultProps = {
  text: 'Hello world'
};

// App.jsx
function App() {
  return <Title text='Hello React' />;
}
```

`Title` 组件只有一个输入属性 `text` 。父组件 (`App`) 在使用 `<Title>` 标签时提供此属性。在定义组件的同时我们还定义了 `propTypes` 。在 `propTypes` 中我们定义了每个属性的类型，这样的话，当某些属性的类型并非我们所预期时，React 会在控制台中进行提示。`defaultProps` 是另一个有用的选项。我们可以使用它来为组件的属性设置默认值，这样就算开发者忘记传入属性也能保障组件具有有效值。

React 并没有严格定义传入的属性应该是什么。它可以是任何我们想要传入的。例如，它可以是另外一个组件:

```js
function SomethingElse({ answer }) {
  return <div>The answer is { answer }</div>;
}
function Answer() {
  return <span>42</span>;
}

<SomethingElse answer={ <Answer /> } />
```

还有一个 `props.children` 属性，它可以让我们访问父组件标签内的子元素。例如:

```js
function Title({ text, children }) {
  return (
    <h1>
      { text }
      { children }
    </h1>
  );
}
function App() {
  return (
    <Title text='Hello React'>
      <span>community</span>
    </Title>
  );
}
```

在这个示例中，`App` 组件中的 `<span>community</span>` 就是 `Title` 组件中的 `children` 属性。注意，如果我们将 `{ children }` 从 `Title` 组件中移除，那么 `<span>` 标签将不会渲染。

16.3 版本之前，组件还有一种间接输入，叫做 `context` 。整个 React 组件树可能有一个 `context` 对象，组件树中的每个组件都可以访问它。想了解更多，请阅读 [依赖注入](../chapter-10/README.md) 章节。

## 输出

React 组件第一个明显的输出便是渲染出来的 HTML 。这是我们视觉上能看到的。但是，因为传入的属性可以是任何东西，包括函数，我们可以使用它来发送数据或触发操作。

在下面的示例中，我们有一个组件 `<NameField />`，它接受用户的输入并能将结果发送出去。

<span class="new-page"></span>

```js
function NameField({ valueUpdated }) {
  return (
    <input
      onChange={ event => valueUpdated(event.target.value) } />
  );
};
class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = { name: '' };
  }
  render() {
    return (
      <div>
        <NameField
          valueUpdated={ name => this.setState({ name }) } />
        Name: { this.state.name }
      </div>
    );
  }
};
```

通常，我们需要逻辑的切入点。React 自带了十分方便的生命周期方法，它们可以用来触发操作。例如，在某个页面，我们需要获取外部的数据资源。

```js
class ResultsPage extends React.Component {
  componentDidMount() {
    this.props.getResults();
  }
  render() {
    if (this.props.results) {
      return <List results={ this.props.results } />;
    } else {
      return <LoadingScreen />
    }
  }
}
```

假设，我们要开发一个搜索结果的功能。我们已经有了一个搜索页面，我们在这里进行搜索。当点击提交按钮时，将跳转至 `/results` 页面，这里将显示搜索的结果。当我们进入结果显示页时，我们首先需要渲染加载页面，同时在 `componentDidMount` 生命周期钩子中触发请求结果数据的操作。当得到数据后，我们会将其传给 `<List>` 组件。

## 结语

我们可以将每个 React 组件想象成是一个黑盒，这种方式很不错。它有自己的输入、生命周期及输出。我们所需要做的只是将这些盒子组合起来。这或许就是 React 所提供的优势之一: 易于抽象，易于组合。
