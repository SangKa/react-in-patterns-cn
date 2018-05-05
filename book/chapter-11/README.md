# 组件样式

React 是视图层。因此，它可以控制在浏览器中渲染的标记。众所周知，页面上的 HTML 标记与 CSS 的样式是紧密联系在一起的。有几种方式来处理 React 应用的样式，在本章中我们将一一介绍这些最流行的方式。

## 经典 CSS 类

JSX 语法相当接近于 HTML 语法。因此，我们拥有与 HTML 几乎相同的标签属性，我们仍然可以使用 CSS 类来处理样式。类是定义在外部的 `.css` 文件中的。唯一需要注意的是 React 中使用的是 `className` ，而不是 `class` 。例如:

```html
<h1 className='title'>Styling</h1>
``` 

## 内联样式

内联样式也能很好的工作。类似于 HTML ，我们可以通过 `style` 属性来直接传入样式。但是，`style` 属性在 HTML 中是字符串，而在 JSX 中必须得是一个对象。

```js
const inlineStyles = {
  color: 'red',
  fontSize: '10px',
  marginTop: '2em',
  'border-top': 'solid 1px #000'
};

<h2 style={ inlineStyles }>Inline styling</h2>
```

因为我们用 JavaScript 编写样式，所以从语法角度来看，是有一些限制的。如果我们想要使用原始的 CSS 属性名称，那么我们需要用引号包裹起来，否则需要遵循驼峰式命名规则。但是，使用 JavaScript 编写样式却非常有趣，它比普通的 CSS 更具灵活性。例如样式的继承:

```js
const theme = {
  fontFamily: 'Georgia',
  color: 'blue'
};
const paragraphText = {
  ...theme,
  fontSize: '20px'
};
```

`theme` 中有一些基础样式，然后在 `paragraphText` 中混入 `theme` 的样式。简而言之，我们能够使用 JavaScript 的全部能力来组织 CSS 。重要的是最终生成了一个传给 `style` 属性的对象。

## CSS 模块

[CSS 模块](https://github.com/css-modules/css-modules/blob/master/docs/get-started.md) 是建立在我们到目前为止所介绍过的内容之上的。如果你不喜欢 JavaScript 用法来写 CSS ，那么可以使用 CSS 模块，它可以让我们继续编写普通的 CSS 。通常，这个库是在打包阶段发挥作用的。可以将它作为编译步骤的一部分进行连接，但通常作为构建系统插件分发。

下面的示例可以让你快速对其运行原理有个大致的了解:

<br /><br />

```js
/* style.css */
.title {
  color: green;
}

// App.jsx
import styles from "./style.css";

function App() {
  return <h1 style={ styles.title }>Hello world</h1>;
}
```

默认情况下是无法这样使用的，只有使用了 CSS 模块，我们才能直接导入普通的 CSS 文件并使用其中的类。

当我们提到 *普通的 CSS* ，并非真的指最原始的 CSS 。它支持一些非常有用的组合技巧。例如:

```
.title {
  composes: mainColor from "./brand-colors.css";
}
```

## Styled-components

[Styled-components](https://www.styled-components.com/) 则是另一种完全不同的方向。此库不再为 React 组件提供内联样式。我们需要使用组件来表示它的外观感受。例如，我们创建了 `Link` 组件，它具有特定的风格和用法，而再使用 `<a>` 标签。

```js
const Link = styled.a`
  text-decoration: none;
  padding: 4px;
  border: solid 1px #999;
  color: black;
`;

<Link href='http://google.com'>Google</Link>
```

还有一种扩展类的机制。我们还可以使用 `Link` 组件，但是会改变它的文字颜色，像这样:

```js
const AnotherLink = styled(Link)`
  color: blue;
`;

<AnotherLink href='http://facebook.com'>Facebook</AnotherLink>
```

对我而言，到目前为止 styled-components 可能是多种处理 React 样式的方法中我最感兴趣的。用它来创建组件非常简单，并可以忘记样式本身的存在。如果你的公司有能力创建一个设计系统并用它构建产品的话，那么这个选项可能是最合适的。

## 结语

处理 React 应用的样式有多种方式。我个人在生产环境中试验过所有方式，可以说无所谓对与错。正如 JavaScript 中大多数技术一样，你需要挑选一个更适合你的方式。
