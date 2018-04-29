# 组合 ( composition )

React 最大的好处是它的可组合性。就我个人而言，我不知道还有哪个框架能提供这样如此简单地创建和组合组件的方式。本节我们将探讨一些好用的组合技巧，这些技巧都是经过实战验证的。

我们来看一个简单示例。假设我们的应用有一个头部，我们想在头部中放置导航。我们有三个 React 组件 —`App`、`Header` 和 `Navigation` 。这三个组件是一个嵌套一个的，所以我们得到的依赖关系如下:

```js
<App> -> <Header> -> <Navigation>
```

组合这些组件的简单方法是在需要它们的时候引用即可。

```js
// app.jsx
import Header from './Header.jsx';

export default function App() {
  return <Header />;
}

// Header.jsx
import Navigation from './Navigation.jsx';

export default function Header() {
  return <header><Navigation /></header>;
}

// Navigation.jsx
export default function Navigation() {
  return (<nav> ... </nav>);
}
```

但是，这种方式会引入一些问题:

* 我们可以把 `App` 看作是主要的组合场所。`Header` 可能还有其他元素，比如 logo、搜索框或标语。如果它们是以某种方式通过 `App` 组件传入的就好了，这样我们就无需创建目前这种硬编码的依赖关系。再比如说我们如果需要一个没有 `Navigation` 的 `Header` 组件该怎么办？我们无法轻松实现，因为我们将这两个组件紧绑在了一起。
* 代码很难测试。在 `Header` 中或许有一些业务逻辑，要测试它的话我们需要创建出一个组件实例。但是，因为它还导入了其他组件，所以我们还要为这些导入的组件创建实例，这样的话测试就变的很重。如果 `Navigation` 组件出了问题，那么 `Header` 组件的测试已将被破坏，这完全不是我们想要的效果。*(注意: [浅层渲染 ( shallow rendering )](https://facebook.github.io/react/docs/test-utils.html#shallow-rendering) 通过不渲染 `Header` 组件嵌套的子元素能在一定程度上解决此问题。)*

## 使用 React children API

React 提供了便利的 [`children`](https://facebook.github.io/react/docs/multiple-components.html#children) 属性。通过它父组件可以读取/访问它的嵌套子元素。此 API 可以使得 `Header` 组件不用知晓它的嵌套子元素，从而解放之前的依赖关系:

```js
export default function App() {
  return (
    <Header>
      <Navigation />
    </Header>
  );
}
export default function Header({ children }) {
  return <header>{ children }</header>;
};
```

注意，如果不在 `Header` 中使用 `{ children }` 的话，那么 `Navigation` 组件永远不会渲染。

现在 `Header` 组件的测试变得更简单了，因为完全可以使用空 `<div>` 来渲染 `Header` 组件。这会使用组件更独立，并让我们专注于应用的一小部分。

## 将 child 作为 prop 传入

每个 React 组件都接收属性。正如之前所提到的，关于传入的属性是什么并没有任何严格的规定。我们甚至可以传入其他组件。

```js
const Title = function () {
  return <h1>Hello there!</h1>;
}
const Header = function ({ title, children }) {
  return (
    <header>
      { title }
      { children }
    </header>
  );
}
function App() {
  return (
    <Header title={ <Title /> }>
      <Navigation />
    </Header>
  );
};
```

当遇到像 `Header` 这样的组件时，这种技术非常有用，它们需要对其嵌套的子元素进行决策，但并不关心它们的实际情况。

## 高阶组件

很长一段时期内，高阶组件都是增强和组合 React 元素的最流行的方式。它们看上去与 [装饰器模式](http://robdodson.me/javascript-design-patterns-decorator/) 十分相似，因为它是对组件的包装与增强。

从技术角度来说，高阶组件通常是函数，它接收原始组件并返回原始组件的增强/填充版本。最简单的示例如下:

```js
var enhanceComponent = (Component) =>
  class Enhance extends React.Component {
    render() {
      return (
        <Component {...this.props} />
      )
    }
  };

var OriginalTitle = () => <h1>Hello world</h1>;
var EnhancedTitle = enhanceComponent(OriginalTitle);

class App extends React.Component {
  render() {
    return <EnhancedTitle />;
  }
};
```

高阶组件要做的第一件事就是渲染原始组件。将高阶组件的 `props` 传给原始组件是一种最佳实践。这种方式将保持原始组件的输入。这便是这种模式的最大好处，因为我们控制了原始组件的输入，而输入可以包含原始组件通常无法访问的内容。假设我们有 `OriginalTitle` 所需要的配置:

```js
var config = require('path/to/configuration');

var enhanceComponent = (Component) =>
  class Enhance extends React.Component {
    render() {
      return (
        <Component
          {...this.props}
          title={ config.appTitle }
        />
      )
    }
  };

var OriginalTitle  = ({ title }) => <h1>{ title }</h1>;
var EnhancedTitle = enhanceComponent(OriginalTitle);
```

`appTitle` 是封装在高阶组件内部的。`OriginalTitle` 只知道它所接收的 `title` 属性，它完全不知道数据是来自配置文件的。这就是一个巨大的优势，因为它使得我们可以将组件的代码块进行隔离。它还有助于组件的测试，因为我们可以轻易地创建 mocks 。

这种模式的另外一个特点是为附加的逻辑提供了很好的缓冲区。例如，如果 `OriginalTitle` 需要的数据来自远程服务器。我们可以在高阶组件中请求此数据，然后将其作为属性传给 `OriginalTitle` 。

<span class="new-page"></span>

```js
var enhanceComponent = (Component) =>
  class Enhance extends React.Component {
    constructor(props) {
      super(props);

      this.state = { remoteTitle: null };
    }
    componentDidMount() {
      fetchRemoteData('path/to/endpoint').then(data => {
        this.setState({ remoteTitle: data.title });
      });
    }
    render() {
      return (
        <Component
          {...this.props}
          title={ config.appTitle }
          remoteTitle={ this.state.remoteTitle }
        />
      )
    }
  };

var OriginalTitle  = ({ title, remoteTitle }) =>
  <h1>{ title }{ remoteTitle }</h1>;
var EnhancedTitle = enhanceComponent(OriginalTitle);
```

这次，`OriginalTitle` 只知道它接收两个属性，然后将它们并排渲染出来。它只关心数据的表现，而无需关心数据的来源和方式。

* 关于高阶组件的创建问题，[Dan Abramov](https://github.com/gaearon) 提出了一个 [非常棒的观点](https://github.com/krasimir/react-in-patterns/issues/12)，像调用 `enhanceComponent` 这样的函数时，应该在组件定义的层级调用。换句话说，在另一个 React 组件中做这件事是有问题的，它会导致应用速度变慢并导致性能问题。 *

<br /><br />

## 将函数作为 children 传入和 render prop

最近几个月来，React 社区开始转向一个有趣的方向。到目前为止，我们的示例中的 `children` 属性都是 React 组件。然而，有一种新的模式越来越受欢迎，`children` 属性是一个 JSX 表达式。我们先从传入一个简单对象开始。

```js
function UserName({ children }) {
  return (
    <div>
      <b>{ children.lastName }</b>,
      { children.firstName }
    </div>
  );
}

function App() {
  const user = {
    firstName: 'Krasimir',
    lastName: 'Tsonev'
  };
  return (
    <UserName>{ user }</UserName>
  );
}
```

这看起来有点怪怪的，但实际上它确实非常强大。例如，当某些父组件所知道的内容不需要传给子组件时。下面的示例是待办事项的列表。`App` 组件拥有全部的数据，并且它知道如何确定待办事项是否完成。`TodoList` 组件只是简单地封装了所需的 HTML 标记。

<br /><br /><br /><br />

```js
function TodoList({ todos, children }) {
  return (
    <section className='main-section'>
      <ul className='todo-list'>{
        todos.map((todo, i) => (
          <li key={ i }>{ children(todo) }</li>
        ))
      }</ul>
    </section>
  );
}

function App() {
  const todos = [
    { label: 'Write tests', status: 'done' },
    { label: 'Sent report', status: 'progress' },
    { label: 'Answer emails', status: 'done' }
  ];
  const isCompleted = todo => todo.status === 'done';
  return (
    <TodoList todos={ todos }>
      {
        todo => isCompleted(todo) ?
          <b>{ todo.label }</b> :
          todo.label
      }
    </TodoList>
  );
}
```

注意观察 `App` 组件是如何不暴露数据结构的。`TodoList` 完全不知道 `label` 和 `status` 属性。

名为 *render prop* 的模式与上面所讲的基本相同，除了渲染待办事项使用的是 `render` 属性，而不是 `children` 。

<br /><br /><br />

```js
function TodoList({ todos, render }) {
  return (
    <section className='main-section'>
      <ul className='todo-list'>{
        todos.map((todo, i) => (
          <li key={ i }>{ render(todo) }</li>
        ))
      }</ul>
    </section>
  );
}

return (
  <TodoList
    todos={ todos }
    render={
      todo => isCompleted(todo) ?
        <b>{ todo.label }</b> : todo.label
    } />
);
```

这两种模式 *将函数作为 children 传入* 和 *render prop* 是我最新非常喜欢的。当我们想要复用代码时，它们提供了灵活性和帮助。它们还是抽象命令式代码的强力方式。

```js
class DataProvider extends React.Component {
  constructor(props) {
    super(props);

    this.state = { data: null };
    setTimeout(() => this.setState({ data: 'Hey there!' }), 5000);
  }
  render() {
    if (this.state.data === null) return null;
    return (
      <section>{ this.props.render(this.state.data) }</section>
    );
  }
}
```

`DataProvider` 刚开始不渲染任何内容。5 秒后我们更新了组件的状态并渲染出一个 `<section>`，`<section>` 的内容是由 `render` 属性返回的。可以想象一下同样的组件，数据是从远程服务器获取的，我们只想数据获取后才进行显示。

```js
<DataProvider render={ data => <p>The data is here!</p> } />
```

我们描述了我们想要做的事，而不是如何去做。细节都封装在了 `DataProvider` 中。最近，我们在工作中使用这种模式，我们必须将某些界面限制只对具有 `read:products` 权限的用户开放。我们使用的是 *render prop* 模式。

```js
<Authorize
  permissionsInclude={[ 'read:products' ]}
  render={ () => <ProductsList /> } />
```

这种声明式的方式相当不错，不言自明。`Authorize` 会进行认证，以检查当前用户是否具有权限。如果用户具有读取产品列表的权限，那么我们便渲染 `ProductList` 。

## 结语

你是否对为何还在使用 HTML 感到奇怪？HTML 是在互联网创建之初创建的，直到现在我们仍然在使用它。原因在于它的高度可组合性。React 和它的 JSX 看起来像进化的 HTML ，因此它具备同样的功能。因此，请确保精通组合，因为它是 React 最大的好处之一。
