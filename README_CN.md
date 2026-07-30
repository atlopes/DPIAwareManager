# DPIAwareManager
[English](README.md)|[简体中文](README_CN.md)

_翻译：xinjie   2021.08.03_

一个用于 VFP 应用的 DPI 感知管理器类

## 用途

DPIAwareManager 的目的是使 VFP 应用在高 DPI 监视器上更好的使用。

## 问题的产生

现代的 Windows 系统在运行无 DPI 感知的 VFP 应用时，其文本缩放比例被设置为高于 100%，这和其他 Win32 应用没有区别。

Windows 会对渲染的图形对象的位图进行缩放以匹配百分比。因此，这个过程产生的文本和图形并不像开发者最初设计的那样清晰。

另一方面，如果 VFP9 应用使用 90 报表引擎，那么也就意味着报表对象的错位和尺寸的不正确。

## 一个鸡肋的解决方案

VFP9 应用可以包含一个声明，告诉 Windows 自己是可以感知 DPI 变化的。

该声明可以让 Windwos 不干涉表单和报表的渲染。就像前面说的那样，也就不会产生模糊和错位的情况。

但是，在另一方面，当显示比例超过 100% 时，这个声明不起作用。在高 DPI 设置的显示器上，VFP 应用会随着显示比例的提高而变得越来越小。

## 一个更彻底的解决方案

DPIAwareManager 类旨在提供一个特定的框架来彻底解决这个问题。应用程序可以使用它来管理屏幕和表单的缩放。

被管理的应用能够感知其运行的显示器的设置，并自动调整图像的位置和大小。

由于这些条件可能会变化，所以，这一过程是持续的。用户可能会将 Screen 或顶层表单移动到不同的显示器，或者更改显示器的显示比例，而管理器会在更改时对其做出响应。

管理器试图在后台静默工作。理想情况下，Screen 和表单甚至都不知道它们已经可以感知这些变化。

对于这种透明，也提供更精细的控制，可以让应用、表单或控件被排除在这种控制之外。

请参考：[Windows 上的高 DPI 桌面应用程序开发](https://docs.microsoft.com/zh-cn/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows)

## 基本使用方法

DPIAwareManager 类在一个 PRG 文件中定义。执行它就可以。

如果需要管理表单或者 `_Screen` 对象，只需要调用 Manage() 方法。对于不同的应用程序框架，你或许要用下面的方式：

```foxpro
* 典型情况下与表单管理器集成
LOCAL DPI AS DPIAwareManager

m.DPI = CREATEOBJECT("DPIAwareManager")
m.DPI.Manage(_Screen)

DO FORM someform.scx NOSHOW NAME formReference LINKED

m.DPI.Manage(m.FormReference)
m.FormReference.Show()
```

在没有全局的表单管理器的情况下，表单也可自己启动自己的 DPI 感知管理器

```foxpro
* 没有表单管理器，表单是“自维护”的
PUBLIC DPI AS DPIAwareManager

m.DPI = CREATEOBJECT("DPIAwareManager")

DO someform.scx

* 表单的 Init() 事件中：
m.DPI.Manage(This)
```

## 参考资料

[wiki](https://github.com/atlopes/DPIAwareManager/wiki).

## 快速测试

管理器是针对每个显示器的，因此，你可以使用具有不同显示比例的显示器进行测试。

要运行测试，你需要在 test 文件夹中编译项目，然后运行 dpi-testing.exe 。

重要提示：可执行文件名必须是"dpi-testing.exe"，以便使用应用程序清单。

如果你想在自己的表单中进行测试，那么你可以在 test 文件夹中放入自己表单的副本，并处理好错误处理程序，因为这里没有任何的错误处理程序。

你或许想试试顶层表单，或者在屏幕中的表单，或者在几个不同的显示器上用几个顶层表单进行测试，那么，你可以试试:)

重要提示：这是一项正在进行的工作。它并没有进行过更全面的测试。你需要做好备份工作，以免发生意外！

## 鸣谢

- DPIAwareManager 类中的缩放器是建立在 Irwin Rodriguez 的 [VFPStretch](https://github.com/Irwin1985/VFPStretch) 逻辑基础之上；
- DPI-Testing 应用使用了 Cesar Chalom 的 [FoxyDialog](http://vfpimaging.blogspot.com/2020/06/foxydialogs-v10-going-much-forward-with.html)，它需要 Christian Ehlscheid 的 [VFP2C32-英文](https://github.com/ChristianEhlscheid/vfp2c32)([VFP2C32-简体中文](https://github.com/vfp9/vfp2c32))；
- 图标由 [Icons8](https://icons8.com/) 提供，它是非凡的图标创造者。
