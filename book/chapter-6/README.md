# 展示型组件和容器型组件

万事开头难。React 也不例外，作为初学者，我们也有一大堆问题。我应该将数据放在何处？如何进行变化通知？如何管理状态？这些问题的答案往往与上下文有关，而有时取决于 React 的实战经验。但是，有一种广泛使用的模式，有助于组织基于 React 的应用，那便是将组件分为展示型组件和容器型组件。

我们先从一个简单示例开始，首先说明此示例的问题，然后将组件分成容器型组件和展示型组件。示例中使用的是 `Clock` 组件，它接收 [Date](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date) 对象作为属性并显示实时时间。

```js
class Clock extends React.Component {
  constructor(props) {
    super(props);
    this.state = { time: this.props.time };
    this._update = this._updateTime.bind(this);
  }
  render() {
    const time = this._formatTime(this.state.time);
    return (
      <h1>
        { time.hours } : { time.minutes } : { time.seconds }
      </h1>
    );
  }
  componentDidMount() {
    this._interval = setInterval(this._update, 1000);
  }
  componentWillUnmount() {
    clearInterval(this._interval);
  }
  _formatTime(time) {
    var [ hours, minutes, seconds ] = [
      time.getHours(),
      time.getMinutes(),
      time.getSeconds()
    ].map(num => num < 10 ? '0' + num : num);

    return { hours, minutes, seconds };
  }
  _updateTime() {
    this.setState({
      time: new Date(this.state.time.getTime() + 1000)
    });
  }
};

ReactDOM.render(<Clock time={ new Date() }/>, ...);
```

在组件的构造函数中，我们初始化了组件的状态，这里只保存了当前时间。通过使用 `setInterval` ，我们每秒更新一次状态，然后组件会重新渲染。要想看起来像个真正的时钟，我们还使用了两个辅助函数: `_formatTime` 和 `_updateTime` 。`_formatTime` 用来提取时分秒并确保它们是两位数的形式。`_updateTime` 用来将 `time` 对象设置为当前时间加一秒。

## 问题

这个组件中做了好几件事，它似乎承担了太多的职责。

* 它通过自身来修改状态。在组件中更改时间可能不是一个好主意，因为只有 `Clock` 组件知道当前时间。如果系统中的其他部分也需要此数据，那么将很难进行共享。
* `_formatTime` 实际上做了两件事，它从时间对象中提取出所需信息，并确保这些值永远以两位数字的形式进行展示。这没什么问题，但如果提取操作不是函数的一部分那就更好了，因为函数绑定了 `time` 对象的类型。即此函数既要知道数据结构，同时又要对数据进行可视化处理。

## 提取出容器型组件

容器型组件知道数据及其结构，以及数据的来源。它们知道是如何运转的，或所谓的*业务逻辑*。它们接收信息并对其进行处理，以方便展示型组件使用。通常，我们使用 [高阶组件](https://github.com/krasimir/react-in-patterns/tree/master/patterns/higher-order-components) 来创建容器型组件，因为它们为我们的自定义逻辑提供了缓冲区。

下面是 `ClockContainer` 的代码:

<span class="new-page"></span>

```js
// Clock/index.js
import Clock from './Clock.jsx'; // <-- 展示型组件

export default class ClockContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = { time: props.time };
    this._update = this._updateTime.bind(this);
  }
  render() {
    return <Clock { ...this._extract(this.state.time) }/>;
  }
  componentDidMount() {
    this._interval = setInterval(this._update, 1000);
  }
  componentWillUnmount() {
    clearInterval(this._interval);
  }
  _extract(time) {
    return {
      hours: time.getHours(),
      minutes: time.getMinutes(),
      seconds: time.getSeconds()
    };
  }
  _updateTime() {
    this.setState({
      time: new Date(this.state.time.getTime() + 1000)
    });
  }
};
```

它接收 `time` (date 对象) 属性，使用 `setInterval` 循环并了解数据 (`getHours`、`getMinutes` 和 `getSeconds`) 的详情。最后渲染展示型组件并传入时分秒三个数字。这里没有任何展示相关的内容。只有*业务逻辑*。

## 展示型组件

展示型组件只涉及组件的外在展现形式。它们会有附加的 HTML 标记来使得页面更加漂亮。这种组件没有任何绑定及依赖。通常都是实现成 [无状态组件](https://facebook.github.io/react/blog/2015/10/07/react-v0.14.html#stateless-functional-components)，它们没有内部状态。

在本示例中，展示型组件只包含两位数的检查并返回 `<h1>` 标签:

```js
// Clock/Clock.jsx
export default function Clock(props) {
  var [ hours, minutes, seconds ] = [
    props.hours,
    props.minutes,
    props.seconds
  ].map(num => num < 10 ? '0' + num : num);

  return <h1>{ hours } : { minutes } : { seconds }</h1>;
};
```

## 好处

将组件分成容器型组件和展示型组件可以增加组件的可复用性。不改变时间或不使用 JavaScript [Date](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date) 对象的应用中，都可以使用 `Clock` 函数/组件。原因是它相当*单纯*，不需要对所需数据的详情有任何了解。

容器型组件封装了逻辑，它们可以搭配不同的展示型组件使用，因为它们不参与任何展示相关的工作。我们上面所采用的方法是一个很好的示例，它阐明了容器型组件是如何不关心展示部分的内容的。我们可以很容易地从数字时钟切换到模拟时钟，唯一的变化就是替换 `render` 方法中的 `<Clock>` 组件。

测试也将变得更容易，因为组件承担的职责更少。容器型组件不关心 UI 。展示型组件只是纯粹地负责展示，它可以很好地预测出渲染后的 HTML 标记。

## 结语

容器型和展示型的并非是新概念，但是它真的非常适合 React 。它使得应用具有更好的结构，易于管理和扩展。
