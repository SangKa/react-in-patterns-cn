# 集成第三方库

React 或许是构建 UI 的最佳选择之一。良好的设计与强大的支持，还有庞大的社区。但是，有些情况下，我们想要使用外部服务或想要集成一些完全不同的东西。众所周知，React 在底层与实际 DOM 有大量的交互并控制页面上渲染什么，基本上它是开发者与实际 DOM 间的桥梁。这也正是为什么 React 集成第三方组件有些麻烦的地方。在本节中，我们将来介绍如何安全地混用 React 和 jQuery 的 UI 插件。

## 示例

我为这个示例挑选了 [*tag-it*](https://github.com/aehlke/tag-it) 这个 jQuery 插件。它将无序列表转换成可以管理标签的输入框：

```html
<ul>
  <li>JavaScript</li>
  <li>CSS</li>
</ul>
```

转换成:

![tag-it](./tag-it.png)

要运行起来，我们需要引入 jQueyr、jQuery UI 和 *tag-it* 插件。这是运行的代码:

```jsx
$('<dom element selector>').tagit();
```

选择 DOM 元素，然后调用 `tagit()` 。

现在，我们来创建一个简单的 React 应用，它将使用 jQuery 插件:

```jsx
// Tags.jsx
class Tags extends React.Component {
  render() {
    return (
      <ul>
      { 
        this.props.tags.map(
          (tag, i) => <li key={ i }>{ tag } </li>
        )
      }
      </ul>
    );
  }
};

// App.jsx
class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = { tags: ['JavaScript', 'CSS' ] };
  }
  render() {
    return (
      <div>
        <Tags tags={ this.state.tags } />
      </div>
    );
  }
}

ReactDOM.render(<App />, document.querySelector('#container'));
```

`App` 类是入口。它使用了 `Tags` 组件，`Tags` 组件会根据传入的 `tags` 属性来展示无序列表。当 React 在页面上渲染列表时就有了 `<ul>` 标签，这样就可以和 jQuery 插件连接起来。

## 强制单通道渲染

首先，我们要做的就是强制 `Tags` 组件进行单通道渲染。这是因为当 React 在实际 DOM 中添加完容器元素后，我们想将控制权交给 jQuery 。如果不做控制的话，那么 React 和 jQuery 将会操纵同一个 DOM 元素而彼此之间不知情。要实现单通道渲染，我们需要使用生命周期方法 `shouldComponentUpdate`，像这样:

```jsx
class Tags extends React.Component {
  shouldComponentUpdate() {
    return false;
  }
  ...
```

这里永远都返回 `false` ，我们想让组件知道永远不进行重新渲染。定义 `shouldComponentUpdate` 对于 React 组件来说，是让其知道是否触发 `render` 方法。这适用于我们的场景，因为我们想使用 React 来添加 HTML 标记，添加完后就不想再依靠 React 。

## 初始化插件

React 提供了 [API](https://facebook.github.io/react/docs/refs-and-the-dom.html) 来访问实际 DOM 节点。我们需要在相应的节点上使用 `ref` 属性，稍后可以通过 `this.refs` 来访问 DOM 。`componentDidMount` 是最适合初始化 *tag-it* 插件的生命周期方法。这是因为当 React 将 `render` 方法返回的结果挂载到 DOM 时才调用此方法。

<br /><br /><br />

```jsx
class Tags extends React.Component {
  ...
  componentDidMount() {
    this.list = $(this.refs.list);
    this.list.tagit();
  }
  render() {
    return (
      <ul ref='list'>
      { 
        this.props.tags.map(
          (tag, i) => <li key={ i }>{ tag } </li>
        )
      }
      </ul>
    );
  }
  ...
```

上面的代码和 `shouldComponentUpdate` 一起使用就会使 React 渲染出有两项的 `<ul>` ，然后 *tag-it* 会其转换成标签可编辑的插件。

## 使用 React 控制插件

假如说我们想要通过代码来为已经运行的 *tag-it* 插件添加新标签。这种操作将由 React 组件触发，并需要使用 jQuery API 。我们需要找到一种方式将数据传递给 `Tags` 组件，但同时还要保持单通道渲染。

为了说明整个过程，我们需要在 `App` 类中添加一个输入框和按钮，点击按钮时将输入框的值传给 `Tags` 组件。

<br />

```jsx
class App extends React.Component {
  constructor(props) {
    super(props);

    this._addNewTag = this._addNewTag.bind(this);
    this.state = {
      tags: ['JavaScript', 'CSS' ],
      newTag: null
    };
  }
  _addNewTag() {
    this.setState({ newTag: this.refs.field.value });
  }
  render() {
    return (
      <div>
        <p>Add new tag:</p>
        <div>
          <input type='text' ref='field' />
          <button onClick={ this._addNewTag }>Add</button>
        </div>
        <Tags
          tags={ this.state.tags }
          newTag={ this.state.newTag } />
      </div>
    );
  }
}
```

我们使用内部状态来存储新添加的标签名称。每次点击按钮时，我就更新状态并触发 `Tags` 组件的重新渲染。但由于 `shouldComponentUpdate` 的存在，页面上不会有任何的更新。唯一的变化就是得到 `newTag` 属性的新值，另一个生命周期方法 `componentWillReceiveProps` 会捕获到属性的新值:

<br /><br /><br />

```jsx
class Tags extends React.Component {
  ...
  componentWillReceiveProps(newProps) {
    this.list.tagit('createTag', newProps.newTag);
  }
  ...
```

`.tagit('createTag', newProps.newTag)` 是纯粹的 jQuery 代码。如果想调用第三方库的方法，`componentWillReceiveProps` 是个不错的选择。

下面是 `Tags` 组件的完整代码:

```jsx
class Tags extends React.Component {
  componentDidMount() {
    this.list = $(this.refs.list);
    this.list.tagit();
  }
  shouldComponentUpdate() {
    return false;
  }
  componentWillReceiveProps(newProps) {
    this.list.tagit('createTag', newProps.newTag);
  }
  render() {
    return (
      <ul ref='list'>
      { 
        this.props.tags.map(
          (tag, i) => <li key={ i }>{ tag } </li>
        ) 
      }
      </ul>
    );
  }
};
```

<br />

## 结语

尽管 React 承担了操纵 DOM 树的工作，但我们仍可以集成第三方的库和服务。生命周期方法让我们在渲染过程中可以进行足够的控制，这样才能够完美地连接 React 和非 React 世界。
