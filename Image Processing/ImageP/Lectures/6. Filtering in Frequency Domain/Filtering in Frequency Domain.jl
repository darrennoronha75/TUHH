### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ c16597c4-9cf9-4a7d-966c-6b6b4aa4765b
begin
	using PlutoUI,Images,TestImages,Interpolations,Plots,Random, LinearAlgebra, FFTW, ImageContrastAdjustment, Statistics, Noise, DSP, TOML, ImageTransformations,CoordinateTransformations, Rotations

	
hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
theorem(text) = Markdown.MD(Markdown.Admonition("correct", "Theorem", [text]))
proof(text) = Markdown.MD(Markdown.Admonition("warning", "Proof", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))
question(text) = Markdown.MD(Markdown.Admonition("correct", "Question", [text]))
	
	PlutoUI.TableOfContents()
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""
# 6. Image Processing - Filtering in Frequency Domain
[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ bdae42a3-8dbe-41ec-911a-89b087b26286
md"## 6.1 Fourier Transformation

The Fourier transform plays a very important role in signal and image processing. In particular it allows to:
* analyse image characteristics in a different (often better) way than in image space
* understand sampling artifacts much better
* separate noise signal from object signal in a more natural way
* apply filters more efficiently
And on top of that the Fourier transformation is a lot of fun!
"

# ╔═╡ f9779b2c-79ce-45f8-a3e7-b4977698748d
note(md"In this lecture we try to capture the most important things about the Fourier transformation and its application. If you have not learned about the Fourier transformation we encourage that you get a book on basic signal processing. Basic knowledge on Fourier series that you learned about in an Analysis lecture is assumed.")

# ╔═╡ 32b546f2-c745-4c32-82f1-2583e8ceb678
note(md"We will introduce most mathematics in 1D since the extension to multiple dimensions is straight forward. Considering it in 1D allows for a more concise presentation.")

# ╔═╡ 64365a87-011f-4814-ab8d-c44cb109063b
md"### 6.1.1 Fourier Series"

# ╔═╡ 651cbf87-6672-45a7-b845-4b3877f8dad2
md"We start with a basic example. Suppose that you have a 1-period function $\text{rect}: [0,1) \rightarrow \mathbb{R}$ with

$\text{rect}(x) = \begin{cases} 1 & \text{if} \quad \frac{1}{4} < x < \frac{3}{4}\\ 
             0 & \text{if} \quad x=\frac{1}{4} \lor x= \frac{3}{4}\\ 
             -1 & \text{otherwise}
           \end{cases}$ 

and you want to express this function using a sum of sine functions. Then, one can show that the $\text{rect}$ function can be expressed as

$\begin{align}
  \text{rect}(x) & = \frac{4}{\pi } \left[\sin(2\pi x)+{\frac{1}{3}}\sin(6\pi x)+{\frac{1}{5}}\sin(10\pi x)+\ldots \right] \\
    & =\frac{4}{\pi}\sum_{k=1}^{\infty}{\frac{\sin((2k-1)2\pi x)}{2k-1}}
\end{align}$


"

# ╔═╡ a841d668-7de4-4187-95bd-611fc57799ef
md"
The shown sum is the so-called Fourier series and for a general $P$-period function it can be expressed as

$f(x)=\sum_{n=-\infty}^{\infty} c_{n}\, e^{i{\tfrac{2\pi}{P}}nx}.$

The Fourier coefficients $c_n$ can be calculated by

$c_n= \frac{1}{P}\int_{0}^{P} f(x)\, e^{-i{\tfrac{2\pi}{P}}nx} \text{d}x.$

Here, it does not matter over which part of the function is integrated as long as it is a full period.
"

# ╔═╡ c9497b69-6390-40a7-99bf-7f80f3546350
note(md"Not every P-periodic function has a Fourier series. A sufficient criterion is the fulfillment of the [Dirichlet_conditions] (https://en.wikipedia.org/wiki/Dirichlet_conditions) that require: \
➔  $f$ must be absolutely integrable over a period. \
➔  $f$ must be of bounded variation in any given bounded interval. \
➔  $f$ must have a finite number of discontinuities in any given bounded interval, and the discontinuities cannot be infinite.
")

# ╔═╡ 0028ed4f-495d-4f3b-beb5-c4a9f3ceb176
md"### 6.1.2 Example
The following shows the Fourier approximation of the rectangular function taking only $n<N$ summands into account. With this slider 

  N = $(@bind N Slider(1:2:1000; default=11, show_value=true)) 

you can control the number of summands being included:"

# ╔═╡ 965a2685-c1c8-40ad-8de7-191a52c2d79c
let
	M = 2000
	t = range(0,1,length=M)
	
	rect(t) = t < 0.25 ? -1.0 : (t > 0.75 ? -1.0 : 1.0)
	
	rect_approx(t,N) = sum([ 4/(π*n)*sin(2*pi*(t-0.25)*n) for n=1:2:N]) 
	
	p = plot(t,rect.(t),label="rect")
	plot!(p,t,rect_approx.(t,N),label="rect_approx")
end

# ╔═╡ 7f332548-6437-4e7f-92d1-c73eeecec442
md"
##### Observations
1. The more terms we use, the better is the approximation. 
2. A Fourier approximation often show a *ringing* effect. This ringing is more pronounced at dis discontinuities (i.e. edges) and called [Gibbs ringing](https://en.wikipedia.org/wiki/Gibbs_phenomenon). We will investigate this later."

# ╔═╡ 783e83f4-95f7-4300-8449-b33d282fe303
question(md"Why is the Fourier series still exact although all(!) finite approximations show an almost constant *jump height* of the ringing?
	
Hint: Think about what happens in the limit $N\rightarrow \infty.$	
")

# ╔═╡ bb489eac-ad51-4529-8069-2fbc47ca682b
md"## 6.2 Continuous Fourier Transform

The Fourier series is restricted to periodic functions, which is clear since the base functions are periodic. But it can be generalized to non-periodic functions resulting the the continuous Fourier transform that is defined as

$({\cal F}f)(\xi) = \hat{f}(\xi) = \int_{-\infty}^{\infty} f(x)\, \text{e}^{-2\pi i x\xi} \text{d}x.$

It also has an associated inverse that can be calculated by

$({\cal F}^{-1}\hat{f})(x) = f(x) = \int_{-\infty}^{\infty} \hat{f}(\xi)\, \text{e}^{2\pi i x\xi} \text{d}\xi$

One can derive this by considering the limit $P\rightarrow \infty$ in the definition of the Fourier series, i.e. one is basically stretching one period over the entire real line.


"

# ╔═╡ 934023e2-c4bb-462b-8663-b4b48b341944
md"
The Fourier transformation and its inverse only exists under certain circumstances.  A sufficient criterion for this is that $f$ and its inverse are both functions from the space of integrable functions $L^1(\mathbb{R})$, i.e. $f$ and its inverse fulfill

$\begin{align}
 & \Vert f(x) \Vert_1 :=  \int_{-\infty}^{\infty}  \vert f(x) \vert \text{d} x   < \infty 
\end{align}$

This criterion directly derives from the definition of the Fourier transform when considering $\xi=0$ (or $x=0$ for the inverse), which basically integrates the function over the entire real line.
"

# ╔═╡ 65d5cbb7-eb7e-4724-8444-e65d91c1ed4e
note(md"The existence of Fourier integrals goes far beyond the scope of the present lecture and requires proper knowledge of [functional analysis](https://en.wikipedia.org/wiki/Functional_analysis). But note that there are cases where the sufficient criterion is not fulfilled but a Fourier transform can still be applied.")

# ╔═╡ 05884c26-45e0-4403-9032-dfcb9504b6c9
md"The functions $f$ and $\hat{f}$ are often denoted as a Fourier transformation pair which is graphically shown as

${\displaystyle f(x)\ {\stackrel {\mathcal {F}}{\longleftrightarrow }}\ {\hat {f}}(\xi )}.$

Here is a table of some important Fourier relations:"

# ╔═╡ 35dbfaf5-26cb-4400-9dc4-00457c0f2d6e
md"
|  $f(x)$ | $\hat{f}(\xi)$ |
|:-----|:------|
| $1$    |   $\delta(\xi) = {\displaystyle\lim_{p\rightarrow \infty}}\; p\;\text{rect}(\frac{\xi}{p})$ |
| $\text{rect}(x)$    |   $\text{sinc}(\xi) = \frac{\sin (\pi\xi)}{\xi}$ |
| $\text{e}^{2\pi i\xi_0 x}$    |   $\delta(\xi-\xi_0)$ |
| $\cos(2\pi \xi_0 x)$    |   $\tfrac{1}{2}(\delta(\xi+\xi_0) + \delta(\xi-\xi_0))$ |
| $\sin(2\pi \xi_0 x)$    |   $\tfrac{i}{2}(\delta(\xi+\xi_0) - \delta(\xi-\xi_0))$ |
| $\text{e}^{ -ax^2}$    |   $\sqrt{\frac{\pi}{a}} \text{e}^{ - \frac{\pi^2\xi^2}{a}}$ |
| $\frac{\text{d}^d}{\text{d}^d x} f(x)$    |   $(2\pi \xi_0)^d \hat{f}(\xi)$ |
| $\displaystyle\sum_{n=-\infty}^{\infty} \delta(x-nX)$    |   $\displaystyle\frac{1}{X}\sum_{n=-\infty}^{\infty} \delta(\xi-\frac{n}{X})$ |
|  $f(x-x_0)$ | ${\mathrm {e} ^{-\mathrm {i} 2\pi x_0 \xi}\hat{f}(\xi)}$ |
|  $f(ax)$ | $\frac{1}{\vert a\vert}\hat{f}(\frac{\xi}{a})$ |
"

# ╔═╡ 8482e6f5-5405-4ddf-b379-908984eb61dc
note(md"We encourage you to prove some of these transformation pairs on your own. It gives you a much better understanding of the Fourier transform. You will need some [trigonometric identities](https://en.wikipedia.org/wiki/List_of_trigonometric_identities) for some proves.")

# ╔═╡ 4cc26d05-df6d-4102-89ab-41e0e444ecf7
md"### 6.2.1 Convolution Theorem

One of the most important Fourier relationships is the convolution theorem:
"

# ╔═╡ b24d5a7f-2dfe-41f5-94c9-2019d7e8a5e1
theorem(md"""
Let $g,s,h \in L^1(\mathbb{R})$ be functions that satisfy $\hat{g},\hat{s},\hat{h} \in L^1(\mathbb{R})$. Then, the convolution $g(x) = (s \ast h)(x)$ in spatial space corresponds to a multiplication in Fourier space:
	
$\begin{equation}
\hat{g}(\xi) = \hat{s}(\xi) \hat{h}(\xi)
	\end{equation}.$
""")

# ╔═╡ 1e1c74ae-e429-41cd-8926-7cd843a915d2
proof(md"""
$\begin{align*}
\hat{g}(\xi) & = (\mathcal{F} g)(\xi) = (\mathcal{F} (s \ast h))(\xi)  \\
  &  =  \int_{-\infty}^{\infty} \left(\int_{-\infty}^{\infty} s(\tilde{x}) h(x-\tilde{x}) \text{d} \tilde{x}\right) \text{e}^{-2\pi i x\xi} \text{d} x \\ 
  &  =  \int_{-\infty}^{\infty} \int_{-\infty}^{\infty} s(\tilde{x}) h(x-\tilde{x}) \text{e}^{-2\pi i (x-\tilde{x})\xi}  \text{e}^{-2\pi i \tilde{x}\xi} \text{d} \tilde{x} \text{d} x \\ 
 &  =  \int_{-\infty}^{\infty} \int_{-\infty}^{\infty}  s(\tilde{x})    h(z) \text{e}^{-2\pi i \tilde{x}\xi} \text{e}^{-2\pi i z\xi}  \text{d} \tilde{x} \text{d} z \\ 
   &  =  \int_{-\infty}^{\infty} s(\tilde{x}) \text{e}^{-2\pi i \tilde{x}\xi} \text{d} \tilde{x}  \int_{-\infty}^{\infty}  h(z) \text{e}^{-2\pi i z\xi}  \text{d} z \\ 
  & = \hat{s}(\xi) \hat{h}(\xi) 
	\end{align*}$
""")

# ╔═╡ 69a85587-3652-4eb0-84f6-4031c181c6ce
md"What this basically tells us is that we can apply a convolution in Fourier space much easier by just a multiplication. This multiplication is what we originally understand by *filtering*."

# ╔═╡ 7cc2f478-dcca-4f3b-af6b-e35d3845296d
md"### 6.2.2 Filtering

The convolution theorem gives us a general pattern how we can apply convolution/filter operation in Fourier space. It consists of the following three steps to compute $(s\ast h)(x)$:
1. Calculate the Fourier transforms $\hat{s}(\xi)$ and $\hat{h}(\xi)$ 
2. Apply the filter by calculating $\hat{d}(\xi) = \hat{s}(\xi) \hat{h}(\xi)$ 
3. Apply the inverse Fourier transform to $\hat{d}(\xi)$ yielding $d(x) = (s\ast h)(x)$
"

# ╔═╡ 556807bc-0b10-44e7-be21-047a5828e3c5
note(md"While this general pattern also holds in the discrete setting you will need to account for some additional things like fftshift and padding.")

# ╔═╡ b491af95-45c1-4a72-8db4-12eeb74d8f85
md"### 6.2.3 Multi-Dimensional Fourier Transform

The multidimensional Fourier transform is defined as


$({\cal F}f)(\mathbf{k}) = \hat{f}(\mathbf{k}) = \int_{-\infty}^{\infty} f(\mathbf{r})\, \text{e}^{-2\pi i \mathbf{r}^\intercal\mathbf{k}} \text{d}\mathbf{r}.$

It also has an associated inverse that can be calculated by

$({\cal F}^{-1}\hat{f})(\mathbf{r}) = f(\mathbf{r}) = \int_{-\infty}^{\infty} \hat{f}(\mathbf{k})\, \text{e}^{2\pi i\mathbf{r}^\intercal\mathbf{k}} \text{d}\mathbf{k}.$

So the difference is that we have the inner product $\mathbf{r}^\intercal\mathbf{k}$ in the exponent and that the integration is multidimensional. Since

$\text{e}^{a+b} = \text{e}^{a} \text{e}^{b}$

one can see that the term $\mathbf{r}^\intercal\mathbf{k}$ naturally arises from a tensor product approach of the exponential base functions.


"

# ╔═╡ a1d4c03a-4f30-47b1-afaf-7fd7afbf5c52
md"## 6.3 Fourier Transform on Images

Before we discuss the mathematics further, we want to look at some actual data:
"

# ╔═╡ c8b68e02-e078-4ce2-bc60-8d8774f13bc9
begin
  img = imresize(Float64.(testimage("mandril_gray")),256,256);
  fabio = Float64.(testimage("fabio_gray"));
  function ftAmpDisplay(img)
    imgFT = log.(fftshift(abs.(fft(img))))
	return imgFT ./ maximum(imgFT)
  end
  function ftPhaseDisplay(img)
    imgFT = fftshift(angle.(fft(img)))
	return imgFT ./ maximum(imgFT)
  end
  function ftAmpDisplayNonShifted(img)
    imgFT = log.(abs.(fft(img)))
	return imgFT ./ maximum(imgFT)
  end
end;

# ╔═╡ f3f024e1-7b00-4170-9b0e-c9473795ebeb
plot(
  heatmap(Gray.(img),title="image space"),
  heatmap(Gray.(ftAmpDisplay(img)),title="Fourier space amplitude"),
  heatmap(Gray.(ftPhaseDisplay(img)),title="Fourier space phase"),
  layout=(1,3), size=(800,255)
)

# ╔═╡ 247459cb-8713-43c6-afe2-88ba385dd663
md"##### Observations
* Fourier space has a higher signal in the center
* It needs to be shown in a logarithmic fashion since otherwise only the center would be visible.
"

# ╔═╡ b34e9617-70e3-42d6-aae9-c8f86282c5d0
md"### 6.3.1 Amplitude vs Phase

It is an interesting question whether the main image information is encoded in the phase or in the amplitude. This can be tested as follows:
"

# ╔═╡ 7bbfa928-2f65-40a4-b359-10ed9f73eab8
begin
switchA = real.(ifft(abs.(fft(img)).*exp.(im.*angle.(fft(fabio)))))
switchB = real.(ifft(abs.(fft(fabio)).*exp.(im.*angle.(fft(img)))))
plot(
  heatmap(Gray.(img),title="image space"),
  heatmap(Gray.(ftAmpDisplay(img)),title="Fourier space amplitude"),
  heatmap(Gray.(ftPhaseDisplay(img)),title="Fourier space phase"),
  heatmap(Gray.(fabio)),
  heatmap(Gray.(ftAmpDisplay(fabio))),
  heatmap(Gray.(ftPhaseDisplay(fabio))),
  heatmap(Gray.(switchA)),
  heatmap(Gray.(ftAmpDisplay(switchA))),
  heatmap(Gray.(ftPhaseDisplay(switchA))),	
  heatmap(Gray.(switchB)),
  heatmap(Gray.(ftAmpDisplay(switchB))),
  heatmap(Gray.(ftPhaseDisplay(switchB))),	
  layout=(4,3), size=(800,1100)
)
end

# ╔═╡ e3f5467d-7e4b-437b-b26e-e297a84d2089
md"Thus, phase is actually very important and cannot be simply left away. This is actually not too much of a surprise because in the phase the actual positioning of pixels is encoded. If you take a Dirac delta in image space and shift it around this will change only the phase in Frequency space:

${\delta(x-x_0)\ {\stackrel {\mathcal {F}}{\longleftrightarrow }}}\ {{\mathrm {e} ^{-\mathrm {i} 2\pi x_0 \xi}}}.$
"

# ╔═╡ 913d9ff7-48e0-42c7-8602-cc0374564d47
md"### 6.3.2 Encoding Properties

We next want to have a look what different parts of the Fourier space actually encode. To this end we set certain parts of frequency space to zero and look at the effect on the resulting image in image space.
"

# ╔═╡ c56cd0be-9f79-431f-a3db-fca51711d0e2
let
ftLP = (fft(fabio))
ftLP[:,17:240] .= 0.0
ftLP[17:240,:] .= 0.0
fabioLP = ifft((ftLP))#*10	
	
ftHP = fftshift(fft(fabio))
ftHP[112:145,112:145] .= 0.0
fabioHP = ifft(ifftshift(ftHP))*10
	
plot(
  heatmap(Gray.(fabio),title="image space"),
  heatmap(Gray.(ftAmpDisplay(fabio)),title="Fourier space amplitude"),
  heatmap(Gray.(real.(fabioLP))),
  heatmap(Gray.(ftAmpDisplay(fabioLP))),
  heatmap(Gray.(real.(fabioHP))),
  heatmap(Gray.(ftAmpDisplay(fabioHP))),
  layout=(3,2), size=(800,1230)
)
end

# ╔═╡ a8a82a9b-8ad3-419f-81af-22c881327797
md"##### Observations
* Preserving the central part of the frequency space (low frequency part) leads to a blurred image.
* Preserving the outer part of the frequency space (high frequency part) leads to an  edge image.
"

# ╔═╡ f8185fba-a26c-4625-b9a6-2faf657fecef
md"### 6.3.3 Geometric Transformations

Let us have a look what happens if we apply geometric transformations. If we shift our image in image space, the Fourier transform will be weighted with a  phase:


${\displaystyle f(x+x_0,y+y_0)\ {\stackrel {\mathcal {F}}{\longleftrightarrow }}\ {  \text{e}^{2\pi i(x_0 u + y_0 v) } \hat {f}}(u,v) }.$

In images this looks like this:
"

# ╔═╡ ca7f36ee-3905-4c43-be93-41352cafcc84
begin
fabioShift =  circshift(img, (100,100))
	
plot(
  heatmap(Gray.(img),title="image space"),
  heatmap(Gray.(ftAmpDisplay(img)),title="Fourier space amplitude"),
  heatmap(Gray.(ftPhaseDisplay(img)),title="Fourier space phase"),
  heatmap(Gray.(fabioShift)),
  heatmap(Gray.(ftAmpDisplay(fabioShift))),
  heatmap(Gray.(ftPhaseDisplay(fabioShift))),
  layout=(2,3), size=(800,520)
)
end

# ╔═╡ a15b8d86-57cd-482e-a8f5-2dc276c050f3
md"For an image rotation with the rotation matrix $\mathbf{R}_\alpha$ and its inverse
$\mathbf{R}_\alpha^{-1} = \mathbf{R}_\alpha^{T}$
we can calculate the Fourier transform of $f(\mathbf{R}_\alpha\mathbf{r})$:

$\begin{align}
({\cal F}f(\mathbf{R}_\alpha\mathbf{r}))(\mathbf k) &= \int_{\mathbb{R}^2} f(\mathbf{R}_\alpha\mathbf{r})\, \text{e}^{2\pi i \mathbf{k}^T\mathbf{r} } \text{d}\mathbf{r} \quad | \; \text{subst.}\; \tilde{\mathbf{r}} = \mathbf{R}_\alpha\mathbf{r}\\
&= \int_{\mathbb{R}^2} f(\tilde{\mathbf{r}})\, \text{e}^{2\pi i \mathbf{k}^T\mathbf{R}_\alpha^T\tilde{\mathbf{r}} } \text{d}\tilde{\mathbf{r}}  \\
&= \int_{\mathbb{R}^2} f(\tilde{\mathbf{r}})\, \text{e}^{2\pi i (\mathbf{R}_\alpha \mathbf{k})^T\tilde{\mathbf{r}} } \text{d}\tilde{\mathbf{r}} \\
& = ({\cal F}f(\mathbf{r}))(\mathbf{R}_\alpha\mathbf{k})
\end{align}$

We have used that the determinant of the Jacobian during the substitution is equal to 1. 

Consequently, a rotation in image space corresponds to a rotation in the Fourier space. Lets see, if we can verify this on images:
"

# ╔═╡ c5ae33ed-f899-41e6-b332-c62a2a2ded4c
let
tr2 = recenter(RotMatrix(pi/8), Images.center(fabio))
fabioRot =  collect(warp(img, tr2, fill=0.0))
fabioRot[isnan.(fabioRot)] .= 0.0

plot(
  heatmap(Gray.(img),title="image space"),
  heatmap(Gray.(ftAmpDisplay(img)),title="Fourier space amplitude"),
  heatmap(Gray.(fabioRot)),
  heatmap(Gray.(ftAmpDisplay(fabioRot))),
  layout=(2,2), size=(800,800)
)

end

# ╔═╡ 846c1486-4715-47d7-9f28-8b5b097eda83
md"On a first sight the spectrum is indeed rotated. On a second sight one can see several additional lines appearing. The simple reason for this is that the rotation invariance only holds in the continuous setting. The edges appear due to the sharp edges present in the rotated image shown on the left. These can be removed by cropping the rotated image but the fact remains that the rotation invariance does not hold in the discrete setting:"

# ╔═╡ 4b6f3e71-4fda-4f34-8f90-d753f1a2e4cd
begin
tr2 = recenter(RotMatrix(pi/8), Images.center(fabio))
fabioRot =  warp(img, tr2, fill=0.0)
fabioRot[isnan.(fabioRot)] .= 0.0
fabioRot = fabioRot[32:226,32:226]
	
plot(
  heatmap(Gray.(fabioRot),title="image space"),
  heatmap(Gray.(ftAmpDisplay(fabioRot)),title="Fourier space amplitude"),
  layout=(1,2), size=(800,400)
)
end

# ╔═╡ 92733ef9-df74-47ba-ad25-bb4613c7cc91
md"## 6.4 Discrete Fourier Transform

We have until now considered the continuous Fourier transformation on the real line. In practice, images are discrete and the question is what effect sampling has on the signal and its Fourier transform. Sampling can be expressed as a multiplication of a the signal $s(x)$ with the [Dirac comb](https://en.wikipedia.org/wiki/Dirac_comb), i.e.

$$s_\text{sampled}(x) = s(x) \sum_{n=-\infty}^{\infty} \delta(x-nX)$$

This is illustrated in the following picture:
"

# ╔═╡ 9c599aed-edf7-4f78-8389-4f4ae7e96f7a
PlutoUI.LocalResource("img/Dirac-comb_-_Sampling.png")

# ╔═╡ 9a2a1470-1cbb-481b-97e7-7774c2fc7a01
note(md"The Dirac distribution is here basically only a handy concept. One could also express the discretized function as a step function. The difference is just that the sampled value is either smeared across the entire pixel, or within a single point.")

# ╔═╡ 067aba5b-b04f-433c-96ab-bf91e27f2c7b
md"
If we look closely at the sampling relation we see that we have a multiplication in the spatial domain and thus we can express the sampling in Fourier space as convolution:

$\begin{align} \hat{s}_\text{sampled}(\xi) & = \hat{s}(\xi) \ast \frac{1}{X}\sum_{n=-\infty}^{\infty} \delta(\xi-\frac{n}{X}) \\
&= \int_{-\infty}^{\infty} \hat{s}(\tilde{\xi}) \left( \frac{1}{X}\sum_{n=-\infty}^{\infty} \delta(\xi- \tilde{\xi}-\frac{n}{X}) \right) \text{d}\tilde{\xi} \quad | \; \text{subst.}\; \tilde{\xi} = \xi' + \frac{n}{X} \\
&= \int_{-\infty}^{\infty} \hat{s}( \xi' + \frac{n}{X}) \left( \frac{1}{X}\sum_{n=-\infty}^{\infty} \delta(\xi-\xi') \right) \text{d}\xi' \\
&= \frac{1}{X}\sum_{n=-\infty}^{\infty} \int_{-\infty}^{\infty} \hat{s}( \xi' + \frac{n}{X})  \delta(\xi-\xi')  \text{d}\xi' \\
&= \frac{1}{X}\sum_{n=-\infty}^{\infty}  \hat{s}( \xi + \frac{n}{X})   
\end{align}$
This sum is called the *periodization* of $\hat{s}(\xi)$. In fact $\hat{s}_\text{sampled}(\xi)$ is $1/X$-periodic

$\begin{align}\hat{s}_\text{sampled}(\xi+\frac{\alpha}{X}) &= \frac{1}{X}\sum_{n=-\infty}^{\infty}  \hat{s}( \xi + \frac{\alpha}{X} + \frac{n}{X})  \\ 
&= \frac{1}{X}\sum_{n=-\infty}^{\infty}  \hat{s}( \xi + \frac{\alpha+n}{X} ) \quad | \, \text{subst.} \; \tilde{n} = n + \alpha  \\ 
&= \frac{1}{X}\sum_{\tilde{n}=-\infty}^{\infty}  \hat{s}( \xi + \frac{\tilde{n}}{X} )  \\ 
&=\hat{s}_\text{sampled}(\xi)
\end{align}$
"

# ╔═╡ 7d4ea770-3fde-4a42-bf58-f624ad52404f
note(md"This implies: A periodization in spatial (Fourier) domain leads to a periodization in Fourier (spatial) domain.")

# ╔═╡ 728062d1-2f87-4105-97d8-044345278585
md"We have, by the way, also seen this between when going from the Fourier series to the continuous Fourier transform. 

If we now sample the periodic domain as well we end up at a periodic and discrete signal in both domains leading to the [Discrete Fourier Transform (DFT)](https://en.wikipedia.org/wiki/Discrete_Fourier_transform). The following picture summarizes the four different combinations of Fourier transforms:
"

# ╔═╡ 44ac6be0-054f-4f62-9a5a-bd3d418f083d
LocalResource("img/From_Continuous_To_Discrete_Fourier_Transform.gif")

# ╔═╡ 26699a53-b283-4c2a-a7fb-6e93253be716
md"### 6.4.1 Example

Let us shortly revise the rotation of image, which we proved to be invariant in Fourier space. When looking at periodizations of the images, they look like this:
"

# ╔═╡ fb021197-6728-4159-b97e-ac69a3b52588
let
	NI = (195,195)
	M = 500
	tr2 = recenter(RotMatrix(pi/8), Images.center(fabio))
	fabioRot =  warp(img, tr2, fill=0.0)
	fabioRot[isnan.(fabioRot)] .= 0.0
	fabioRot = fabioRot[32:226,32:226]
	
	fabioNonRot = img[32:226,32:226]
	
	fabioPeriodic = extrapolate(interpolate(fabioNonRot, BSpline(Linear())), Periodic())
	fabioRotPeriodic = extrapolate(interpolate(fabioRot, BSpline(Linear())), Periodic())
			
	plot(heatmap(Gray[fabioPeriodic[x,y] for x=range(-NI[1],NI[1]*2,length=M), y=range(-NI[2],NI[2]*2,length=M)], title="Not Rotated"),
		heatmap(Gray[fabioRotPeriodic[x,y] for x=range(-NI[1],NI[1]*2,length=M), y=range(-NI[2],NI[2]*2,length=M)], title="Rotated"), 
	    heatmap(Gray.(ftAmpDisplay(fabioNonRot))),
		heatmap(Gray.(ftAmpDisplay(fabioRot))), size=(800,800))
end

# ╔═╡ 0c6fba8a-e467-41e6-a51a-9add367799f7
md"Clearly the rotation invariance cannot be fulfilled in the discrete case if the image goes not to zero at the image boundaries. Also this image explains why the cross in Fourier space is not rotated as well. The cross is caused by the edges."

# ╔═╡ a31ac49b-1cdc-4e36-98f1-6d71d60cebf7
md"### 6.4.2 Definition"

# ╔═╡ 1eaaf3d0-bd36-4a38-a2ed-30d36af21c75
md"The DFT is defined as

$\hat{s}(\xi) = \sum_{n=0}^{N-1} s(x) \text{e}^{-2\pi i \frac{x\xi}{N}}.$

It has an associated inverse transform that is defined as

$s(x) = \frac{1}{N}\sum_{n=0}^{N-1} \hat{s}(\xi) \text{e}^{2\pi i \frac{x\xi}{N}}$

The DFT is a linear transform that can be written in matrix-vector notation $\mathbf{F} \mathbf{s} = \hat{\mathbf{s}}$. The matrix fulfills $\mathbf{F}^H \mathbf{F} = N \mathbf{I}$, i.e. with an appropriate scaling factor the Fourier matrix is unitary.
"

# ╔═╡ 5564633f-0c35-46d6-ae5a-c9b66c45d97f
md"## 6.5 Sampling Artifacts

It is important to understand that sampling leads to errors. This means that the DFT is not automatically a good approximation of the Fourier series or the continuous Fourier transform. There are two common errors occurring.
"

# ╔═╡ 4ce37a01-ccc9-435c-9ee6-faa45506f383
md"### 6.5.1 Aliasing Error

Aliasing error happen when function that has no limited support in Fourier space is sampled. Due to the periodization it can happen that the signals fold into each other, which is illustrated in the following picture:
"

# ╔═╡ 9e14f910-b158-4e84-9a46-ae6448f4aca6
LocalResource("img/AliasedSpectrum.png",:width=>600)

# ╔═╡ 0f417e1a-7f5c-4604-9a3a-96e47fb9217f
md"For bandlimited functions, which fulfill the so-called [Nyquist Shannon sampling theorem](https://en.wikipedia.org/wiki/Nyquist–Shannon_sampling_theorem) sampling errors can be avoided:
"

# ╔═╡ 8d15d864-9dc8-4571-8f2c-f516d1ade95f
theorem(md"A signal $s(x)$ that has a bandlimited spectrum $\hat{s}(\xi)$ with bandwidth $B$ can be perfectly reconstructed after sampling $s$ with a sampling frequency $\xi_\text{s} > 2B$.")

# ╔═╡ 7a06e3c1-9f6d-4b02-a3c3-853dbdc65673
md"This perfect reconstruction is achieved by multiplying the Fourier spectrum with a rectangular function, which cuts out exactly one period of the periodic signal.

$\begin{align} \hat{s}_\text{reconstructed}(\xi) & = \hat{s}_\text{sampled}(\xi) \, \text{rect}(\frac{\xi}{\xi_\text{s}}) 
\end{align}$
"

# ╔═╡ afd4c72f-b0c4-4644-90e9-3c52cf2ab24e
LocalResource("img/ReconstructFilter.png",:width=>600)

# ╔═╡ 392075cb-f6f0-42a2-afa8-9e0681b54faa
md"If we consider this filtering in spatial domain the multiplication becomes a convolution with the Fourier transform of the rect function, which is the sinc function:

$\begin{align} s_\text{reconstructed}(x) & = (s_\text{sampled} \ast \xi_\text{s} \text{sinc}(\cdot\,\xi_\text{s}))(x) \\
& = \xi_\text{s}\int_{-\infty}^{\infty} s_\text{sampled}(\tilde{x}) \text{sinc}((x-\tilde{x})\xi_\text{s}) \text{d} \tilde{x}  \\
& =\xi_\text{s}  \int_{-\infty}^{\infty} \left( \sum_{n=-\infty}^{\infty} s(\tilde{x}) \delta(\tilde{x}-\frac{n}{\xi_\text{s}}) \right)  \text{sinc}((x-\tilde{x})\xi_\text{s}) \text{d} \tilde{x}  \\
& = \xi_\text{s} \sum_{n=-\infty}^{\infty}  s(\frac{n}{\xi_\text{s}})   \text{sinc}(\frac{x\xi_\text{s} -n}{\xi_\text{s}} ) \text{d} \tilde{x}  \\
\end{align}$
"

# ╔═╡ 8f0d3bea-1dba-4c55-bcf1-dec560302a7b
md"This means that the discrete signal is replaced by shifted sinc functions. This is in fact an interpolation. However, the oscillating behavior of the sinc function leads to ringing behavior in image space."

# ╔═╡ fc63bc91-a1d3-477e-94b0-d96cb8ad21f7
md"#### Examples

We next look at some examples where aliasing error happen. The first example shows what happens to a 1D signal that is subsampled below the Nyquist theorem. While the sampling points are exactly on the gray function, the interpolating orange function looks only similar if the sampling frequency is chosen high enough."

# ╔═╡ e1f32eb6-e71e-4849-81f9-c8930b2cc1f7
LocalResource("img/Nyquist_sampling.gif",:width=>600)

# ╔═╡ 915b35e0-52d7-4e4a-a83b-47050afe8acf
md"
##### Moire Effect

In the next example we look at the zone plane, which contains increasing frequency in radial direction. One can see that the discretized version looks fine in the center but towards the edges one can see strong artifacts since the wavehill frequency is higher then the sampling frequency. This generation of structural patterns because of  aliasing errors is also called the [Moire effect](https://en.wikipedia.org/wiki/Moiré_pattern)."

# ╔═╡ 30e13d8b-8b92-486b-bb86-992c081248b3
LocalResource("img/aliasing.png",:width=>800)

# ╔═╡ f662100a-9852-40d7-bac5-acefdd136ded
md"The moire effect happens in particular if regular patterns with a certain frequency are undersampled. There are various ways to showcase the Moire effect in image space. 

To analyse it better one can take two grids and rotate or shift them. Although both original grids are structured and have a homogeneous spatial frequency, the overlayed image shows a different frequency which we is due to [interference](https://en.wikipedia.org/wiki/Beat_(acoustics)), i.e. the sum of two similar sine functions leads to a modulation with a sine of a different frequency."

# ╔═╡ e282556f-83ff-4c15-9883-9c6ffc6c9864
md"##### Example: Interference Pattern"

# ╔═╡ 88c1717e-624b-488e-bccc-a913e8772ac4
LocalResource("img/WaveInterference.gif",:width=>400)

# ╔═╡ ebb1c1d3-7ab6-408b-bb6e-aeab86e236ab
md"##### Example: Rotated Grids"

# ╔═╡ 38d9ef3a-27f0-497f-9792-2b62a90b80a4
LocalResource("img/Moiré_grid.svg",:width=>800)

# ╔═╡ 3e917e7b-f08f-4732-8a27-ce84f5573b2d
LocalResource("img/Moire.gif",:width=>200)

# ╔═╡ dbec891c-0db4-4e3f-9e8c-bf10c2f8f89b
md"### 6.5.2 Avoiding Aliasing Errors

One way to mitigate aliasing errors is to sample high enough, and/or explicitly bandlimit the function *before* sampling or resampling. This can be done by the application of a rectangular function in Fourier space. However, this leads to the ringing artifact that we before:

$(@bind N2 Slider(1:1000; default=10, show_value=true)) 
"

# ╔═╡ 46e6a68c-5300-40b7-98a6-5e94a0aced62
let
	M = 500
	t = range(0,1,length=M)
	
	rect(t) = t < 0.25 ? -1.0 : (t > 0.75 ? -1.0 : 1.0)
	hann(n,N) = 0.5*(1-cos(2*pi*n/(N-1)))
	
	rect_approx(t,N) = sum([ 4/(π*n)*sin(2*pi*(t-0.25)*n) for n=1:2:N]) 
	rect_approx_windowed(t,N) = sum([ 4/(π*n)*hann(n+N,2*N)*sin(2*pi*(t-0.25)*n) for n=1:2:N]) 
	
	
	p1 = plot(t,rect.(t),label="rect", size=(600,300), xlabel="x")
	plot!(p1,t,rect_approx.(t,N2),label="rect_approx")
	
	p1
end

# ╔═╡ 4175dc61-6808-453a-85e9-9d115fcc6f65
md"Whenever we cut of in frequency space *sharply*, there will be ringing artifacts. But this can be avoided by using a different window function which is not so sharp as the rect function:"

# ╔═╡ 11631d03-7247-4ab1-86d0-95b1d36d349d
let
	M = 500
	t = range(0,1,length=M)
	
	rect(t) = t < 0.25 ? -1.0 : (t > 0.75 ? -1.0 : 1.0)
	hann(n,N) = 0.5*(1-cos(2*pi*n/(N-1)))
	
	rect_approx(t,N) = sum([ 4/(π*n)*sin(2*pi*(t-0.25)*n) for n=1:2:N]) 
	rect_approx_windowed(t,N) = sum([ 4/(π*n)*hann(n+N,2*N)*sin(2*pi*(t-0.25)*n) for n=1:2:N]) 
	
	
	p2 = plot(t,rect.(t),label="rect", size=(600,300), xlabel="x")
	plot!(p2,t,rect_approx_windowed.(t,N2),label="rect_windowed")
	
	p2
end

# ╔═╡ a4d141a8-d7c5-4889-86b3-d7e0e8de725b
md"In this example we have used the Hann Window, which is defined as

${\displaystyle w(n)={\frac {1}{2}}\left[1-\cos \left({\frac {2\pi n}{N-1}}\right)\right]}$

where $n=0,\dots,N-1$ and $N$ is the number of samples in Fourier space. In our code example we used the sine representation of the Fourier series and thus only need to apply half of the window. 
"

# ╔═╡ 678ea624-19cd-415d-89c4-12a14c4be99a
note(md"Windowing is an important technique that you should always consider when using Fourier techniques in practice. Windowing enforces that Fourier coefficients go smoothly to zero, which avoids the truncation artifacts.")

# ╔═╡ 77b9b789-1576-40dc-a339-d04382bc7ada
md"### 6.5.3 Truncation Error

The second error that we make when transitioning from the continuous to the discrete Fourier transform is that only a finite number of coefficients is spend for the Fourier space signal. This corresponds to cutting out the image in space, i.e. it is the reciprocal to the bandlimitation. 

"

# ╔═╡ 12e81120-5824-445b-a96f-8a90eb7621c9
md"## 6.6 Smoothing Filters

In the next two section we investigate some concrete filters that we considered in the spatial filtering lecture and discuss how they look like in Fourier space. First we discuss smoothing filters. 

Recall that we used smoothing filters in order to reduce the noise. Let us take a line from the Fabio image and put some noise on it:
"

# ╔═╡ 8fa138e8-a9bb-45ea-bcaa-5e48308997e9
begin
	function applyFilter(f,hhat)
		fhat = fftshift(fft(f))
		dhat = fhat .* hhat
		d = real.(ifft(ifftshift(dhat)))
	end
end;

# ╔═╡ e29a16c1-30a0-464f-aceb-e51122174358
let
	N = size(fabio,2)
	signal = fabio[100,:]
	noise = randn(N)*0.05
	
	p1 = plot(signal, label="noise free signal", lw=2, title="image space")
	plot!(p1,signal+noise, label="noisy signal", lw=2, ls=:dash)
	plot!(p1,noise, label="noise", lw=2)
	
	p2 = plot(real.(fftshift(fft(signal))), label="noise free signal", lw=2, title="Fourier space")
	plot!(p2,real.(fftshift(fft(signal+noise))), label="noisy signal", lw=2,ls=:dash)
	plot!(p2,real.(fftshift(fft(noise))), label="noise", lw=2)

	p3 = plot(real.(fftshift(fft(signal))), label="noise free signal", lw=2, title="Fourier space (zoomed)", ylim=(-5,5))
	plot!(p3,real.(fftshift(fft(signal+noise))), label="noisy signal", lw=2, ls=:dash)
	plot!(p3,real.(fftshift(fft(noise))), label="noise", lw=2)	
	
	
	plot(p1,p2,p3,layout=(3,1), size=(800,600))
	
end

# ╔═╡ df773ebd-5126-417c-84c3-cf1936af0655
md"##### Observations
* In image space, the noise and the signal spread over the entire axis.
* In Fourier space, the signal is located around frequency zero and then decreases rapidly.
* Noise on the other hand is distributed equally in Fourier space.

All this means that the higher frequency parts mainly contain noise, while the central part of the frequency space contains the signal. The higher the noise, the smaller is the region we can trust. Consequently we can try separating the low and high frequency part using a filter. There are various ways to do so.
"

# ╔═╡ 719ed4b6-3fbf-47e6-bc29-67873db469b7
md"
### 6.6.1 Ideal Low Pass

The ideal low pass can be written as

$\hat{h}_D(u,v) = \begin{cases} 
1 & \text{if} \; \Vert (u,v)^T \Vert_\infty <D \\
0 & \text{otherwise}
\end{cases}$

One may also use an isotropic form of that

$\hat{h}_D^\text{isotropic}(u,v) = \begin{cases} 
1 & \text{if} \; \Vert (u,v)^T \Vert_2 <D \\
0 & \text{otherwise}
\end{cases}$
"

# ╔═╡ 527cb421-d698-4346-944e-c638b93c6a1e
md"So what we can see is the both filters do their job and reduce the noise. Interesting is how the filters look in image space. since $\text{sinc}(x) {\stackrel {\mathcal {F}}{\longleftrightarrow }}\ \text{rect}(\xi)$ it is clear that the 2D variant is either a tensor product of the sinc or an isotropic version of the sinc. This means:
* In principle the ideal low pass leads to a local averaging as we expect from a smooth kerne in image space.
* They are, however, oscillating, and spread over the entire image. This leads to patch like artifacts in image space.

Next let us switch the kernel and its Fourier transform:
"

# ╔═╡ 8acc7807-bc2e-4ba6-b1fd-e3a917876f6e
function logDisplay(img)
    img2 = log.(10*abs.(img).+1.000)
	return img2 ./ maximum(img2)
end;

# ╔═╡ 933cd9cb-4068-4eff-a489-82fddb78e9e7
let
N = size(fabio)
f = fabio .+ randn(N...)*0.2
idealLowPass = zeros(N...)
	
m=20
idealLowPass[div(N[1],2)-m:div(N[1],2)+m, div(N[2],2)-m:div(N[2],2)+m] .= 1.0
idealLowPass2 = [ sqrt((x-div(N[1],2))^2+(y-div(N[2],2))^2)<=m ? 1.0 : 0.0 
		              for x=1:N[1], y=1:N[2]] 
	
plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(idealLowPass)),title="filter image space"),
  heatmap(Gray.(logDisplay(idealLowPass)),title="filter"),
  heatmap(Gray.(applyFilter(f,idealLowPass)),title="result"),
  heatmap(Gray.(f)),
  heatmap(Gray.(ftAmpDisplay(idealLowPass2))),
  heatmap(Gray.(logDisplay(idealLowPass2))),
  heatmap(Gray.(applyFilter(f,idealLowPass2))),
  layout=(2,4), size=(800,380)
)
end

# ╔═╡ d93e40fc-a458-4926-9a1e-487080fc2464
let
N = size(fabio)
f = fabio .+ randn(N...)*0.2
	
m=1/20
idealLowPass = [ sinc(m*(x-div(N[1],2)))*sinc(m*(y-div(N[2],2))) for x=1:N[1], y=1:N[2]] 
idealLowPass ./= maximum(idealLowPass)

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(idealLowPass)),title="filter image space"),
  heatmap(Gray.(logDisplay(idealLowPass)),title="filter"),
  heatmap(Gray.(applyFilter(f,idealLowPass)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ 65888ce6-74e8-4584-a90d-4f36a8556368
md"This now is exactly the box filter that we considered in the last lecture. We can see that:
* It indeed acts as a low pass filter and lets through the central part of the Fourier space.
* However, it is not isotropic and the sinc like ringing lets certain high frequency regions pass that only contain noise.
"

# ╔═╡ b9fab49f-8ef2-4ffb-82ea-a2f282186dd4
md"### 6.6.2 Gaussian Filter

A much better alternative is, as you already know, the Gaussian filter. It was defined in image space as

$h_\text{Gaussian}^\sigma(x,y) = \frac{1}{2\pi\sigma^2}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right)$

In frequency space on can show that the Gaussian is given by

$\hat{h}_\text{Gaussian}^\sigma(u,v) = \text{exp}\left(-2\pi^2\sigma^2(u^2+v^2) \right).$

Let us see it in action:
"

# ╔═╡ 93298b79-9b23-4dcf-9d1e-240aff6e520d
let
N = size(fabio)
f = fabio .+ randn(N...)*0.2
	
D=10
gaussianLowPass = [ exp(-(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(2*D^2)) for u=1:N[1], v=1:N[2]] 
gaussianLowPass ./= maximum(gaussianLowPass)

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(gaussianLowPass)),title="filter image space"),
  heatmap(Gray.(logDisplay(gaussianLowPass)),title="filter"),
  heatmap(Gray.(applyFilter(f,gaussianLowPass)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ b9e462c3-4f94-419b-958b-111ab0fc046b
md"
##### Observations

* Both the Fourier representation and the image space representation of the filter look much better. 
* No sharp cut in Fourier space and no oscillations in both spaces."

# ╔═╡ 09baa409-a102-4fae-bd52-172ccb9503eb
md"### 6.6.3 Butterworth Filter

The Gauss filter has only one parameter for chosing the size of the kernel in both spaces. What cannot be adjusted is the *sharpness* when going from the pass band to the stop band. A filter that allows this is the butterworth filter:

$\hat{h}_\text{Butterworth}^{D,n}(u,v) = \frac{1}{1+\left(\frac{\Vert (u,v)^T \Vert_2}{D}\right)^{2n}}$

The following shows the filter in action for three different (increasing) $n$. The larger $n$ the sharper the filter. The size of the pass band is adjusted by $D$ (not shown).
"

# ╔═╡ 76abbf87-368e-4c08-9956-a0d93b2d2984
let
N = size(fabio)
f = fabio .+ randn(N...)*0.2
	
D=20
n=1
butterworthLowPass1 = [ 1/(1+(sqrt(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(D))^(2n)) for u=1:N[1], v=1:N[2]] 
n=3
butterworthLowPass2 = [ 1/(1+(sqrt(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(D))^(2n)) for u=1:N[1], v=1:N[2]] 
n=6
butterworthLowPass3 = [ 1/(1+(sqrt(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(D))^(2n)) for u=1:N[1], v=1:N[2]] 

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(butterworthLowPass1)),title="filter image space"),
  heatmap(Gray.(logDisplay(butterworthLowPass1)),title="filter"),
  heatmap(Gray.(applyFilter(f,butterworthLowPass1)),title="result"),
  heatmap(Gray.(f)),
  heatmap(Gray.(ftAmpDisplay(butterworthLowPass2))),
  heatmap(Gray.(logDisplay(butterworthLowPass2))),
  heatmap(Gray.(applyFilter(f,butterworthLowPass2))),
  heatmap(Gray.(f)),
  heatmap(Gray.(ftAmpDisplay(butterworthLowPass3))),
  heatmap(Gray.(logDisplay(butterworthLowPass3))),
  heatmap(Gray.(applyFilter(f,butterworthLowPass3))),
  layout=(3,4), size=(800,580)
)
end

# ╔═╡ 43599259-37fc-4797-bdc7-af9c45c940f1
md"
##### Observations

* The filter characteristic can be adjusted in a very fine granular fashion. 
* Making the filter sharp in one domain always leads to ripple in the other domain. So there is no free lunch."

# ╔═╡ 73671150-acea-4cbd-b40a-a83e1b8cbb1a
md"## 6.7 Sharpening Filters

We can design a sharpening filter using the general approach

$\hat{h}_\text{HP}(u,v) = 1 - \hat{h}_\text{LP}(u,v)$

Let us do this for the butterworth filter:
"

# ╔═╡ e8f826dc-c20a-4511-8052-34ae45a320d3
let
N = size(fabio)
f = fabio 
	
D=9
gaussianLowPass = [ 1-exp(-(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(2*D^2)) for u=1:N[1], v=1:N[2]] 
gaussianLowPass ./= maximum(gaussianLowPass)/3

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(gaussianLowPass)),title="filter image space"),
  heatmap(Gray.(logDisplay(gaussianLowPass)),title="filter"),
  heatmap(Gray.(applyFilter(f,gaussianLowPass)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ 04cd89f8-c09a-4314-9868-cdca44108a18
md"This filter is a high pass filter and in this way only keeps the edge information of the image. In case that we want instead a *sharpening* operation we can use that image and add it to the original image. The original image can be written as

$f(x,y) = (f \ast \delta)(x,y).$

In frequency space this means

$\hat{f}(u,v) = \hat{f}(u,v) \cdot 1(u,v).$

Due to linearity we can thus, instead of adding the original image to the sharpened image, add $1$ to the filter kernel yielding

$\hat{h}_\text{sharpening}(u,v) = 1 + \alpha\hat{h}_\text{HP}(u,v) = 1 + \alpha(1- \hat{h}_\text{LP}(u,v)).$

The parameter $\alpha$ here is used to adjust the amount of the sharpened image that is added to the original one.
"

# ╔═╡ de83fa97-3326-4430-a8a4-04de3376821d
let
N = size(fabio)
f = fabio 
	
D=9
α = 2
gaussianLowPass = [ 1+α*(1-exp(-(((u-div(N[1],2)))^2+(v-div(N[2],2))^2)/(2*D^2))) for u=1:N[1], v=1:N[2]] 
gaussianLowPass ./= maximum(gaussianLowPass)/(1+α)

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(gaussianLowPass)),title="filter image space"),
  heatmap(Gray.(logDisplay(gaussianLowPass)),title="filter"),
  heatmap(Gray.(applyFilter(f,gaussianLowPass)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ 9709cbac-f1b2-45b9-90bc-8d8f9c1df87c
md"### 6.7.1 Laplacian

Recall that the Laplacian was defined as 

$\begin{align} \Delta f &= \frac{\partial^2 f}{\partial^2 x} + \frac{\partial^2 f}{\partial^2 y} 
\end{align}$

We know that a spatial derivative can be expressed in Fourier space as a linear weighting. Thus the Laplacian can be expressed in Fourier space by the filter


$\hat{h}_\text{Laplacian}(u,v) = -4\pi^2 (u^2 + v^2)$

"

# ╔═╡ af790681-6ef3-4b32-b9ea-ddab47f5de0e
let
N = size(fabio)
f = fabio 
	
Laplacian = [ -4π^2*(((u-div(N[1],2)))^2+(v-div(N[2],2))^2) for u=1:N[1], v=1:N[2]] 
Laplacian /= 10000

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(Laplacian)),title="filter image space"),
  heatmap(Gray.(logDisplay(Laplacian)),title="filter"),
  heatmap(Gray.(applyFilter(f,Laplacian)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ cf36d1d9-58aa-488a-bb66-bfc88d0db8a5
md"Again if we add 1 to the filter and appropriately weight the high pass part we can obtain a sharpening filter:"

# ╔═╡ b22168cc-db0e-40bb-a7dc-e0e3955fb1d6
let
N = size(fabio)
f = fabio 
	
Laplacian = [ 4π^2*(((u-div(N[1],2)))^2+(v-div(N[2],2))^2) for u=1:N[1], v=1:N[2]] 
Laplacian /= 40000
Laplacian .+= 1

plot(
  heatmap(Gray.(f),title="image space"),
  heatmap(Gray.(ftAmpDisplay(Laplacian)),title="filter image space"),
  heatmap(Gray.(logDisplay(Laplacian)),title="filter"),
  heatmap(Gray.(applyFilter(f,Laplacian)),title="result"),
  layout=(1,4), size=(800,185)
)
end

# ╔═╡ 628f9fb0-4edf-4045-8e76-751edbbd0c4d
md"## 6.8 Implementation

We next discuss some implementation details when applying the discrete Fourier transform.

"

# ╔═╡ e81e1ce0-9e14-4201-9922-cb8fdd3fb771
md"### 6.8.1 fftshift

When we compare the Fourier series

$f(x)=\sum_{n=-\infty}^{\infty} c_{n}\, e^{2\pi i {\tfrac{nx}{P}}}$

with the (inverse) DFT

$s(x) = \frac{1}{N}\sum_{\xi=0}^{N-1} \hat{s}(\xi) \text{e}^{2\pi i \frac{x\xi}{N}}$

it gets clear is that the summation for the DFT is not centered around zero while it is for the Fourier series. The question is why? 

**Answer:** Because it is the convention. In fact, we know that the discrete Fourier coefficients are periodic

$s(\xi) = s(\xi+nN)$

Thus, instead of the index range $[0,N-1]$ one can also take $[-\frac{N}{2},\frac{N}{2}-1]$. This is often more natural as the zero frequency is then located in the center. Switching between both representations is done by the `fftshift` operation, which is available in most FFT software libraries:
"

# ╔═╡ 8f379fb0-e063-4225-bfed-875702f5a37f
fftshift([1,2,3,4])

# ╔═╡ 225ff0e8-9ffc-4721-8c83-5a74dc8c5fbd
fftshift([1,2,3,4,5])

# ╔═╡ cb2ef181-d336-4037-a4aa-4a43697f5a6c
md"This is how it works in 2D. There the two quarters are exchanged:"

# ╔═╡ f3d8e0e6-c114-4f9d-a4c8-05c02b2d35d9
[1 2; 3 4]

# ╔═╡ d4ab346c-4c01-4fcf-b6e2-c02f20286205
fftshift([1 2; 3 4])

# ╔═╡ b05d5d51-df12-4de0-abda-c41db8be1c75
md"And we can also do this on images:"

# ╔═╡ 3b64d064-0335-4892-810a-9cb8973854b3
let
	plot(heatmap(Gray.(ftAmpDisplayNonShifted(fabio)),title="not shifted"),
		 heatmap(Gray.(ftAmpDisplay(fabio)),title="shifted"), layout=(1,2),size=(800,400))
	
end

# ╔═╡ 13f9a561-4e81-4515-ac72-f7c23a547435
note(md"One can apply a filtering either in the shifted domain or in the regular domain. Important is just that the image and the filter are treated the same way. Also it is important to account for the shift before doing an inverse Fourier transformation.")

# ╔═╡ 154bcfa3-b7b7-403a-99ae-1f3628a021c4
md"### 6.8.2 Padding
The convolution theorem in the continuous domain in principle has an analog formulation in the discrete setting. It is, however, only valid for the cyclic convolution:

$(s \ast h)(x) = \sum_{y=0}^{N-1} s(y) h((x-y) \;\text{mod}\; N)$

In fact, this linear transformation can be written as a matrix-vector multiplication with a [circulant matrix](https://en.wikipedia.org/wiki/Circulant_matrix).

If you compare this with our discussions on *boundary conditions* in the last lecture this means that we actually can only apply the convolution if we consider periodic boundary conditions.

But there is a way to use arbitary boundary conditions and still use the discrete convolution theorem. The idea is to appropriately extend the original image (so-called *padding*) that the periodic convolution is the same as the non-periodic one. This is done by adding zeros outside. Depending on the dimensions of $s$ and $h$ one needs to take more or less zeros.

"

# ╔═╡ b152c693-983f-4a33-a39f-f91d876ea4d7
md"### 6.8.3 Fast Fourier Transform

Until now we have not discussed in any way the computational cost of the convolution and the (discrete) Fourier transform. For a signal/image with $N$ entries and a kernel with $N$ entries, the computational cost for both convolutions and DFTs is ${\cal O}(N^2)$ because a sum over $N$ elements needs to be carried out for each of the $N$ output elements.

Quadratic cost in these operations is much too high in practice. This is both for *computational* but also for *memory* reasons. Lets consider that we have an $6,000 \times 6,000$ sized image where each pixel encodes a 32bit floating point number. Then the image is requires $(6000*6000*4 /1024^2) MB of memory. How large would the convolution or Fourier matrix then be? It would be $(6000*6000*6000*6000*4 /1024^5) PB. So even if you have a PC with 1 TB of main memory, this is 4600 times more.

So the intermediate conclusion is that we cannot explicitely arange the transformation matrix but need to perform the transformations in a matrix-free fashion. But also the computational cost is much too high when evaluating the sums directly.

Fortunately, there is an alternative, which is called the [Fast Fourier transform](https://en.wikipedia.org/wiki/Fast_Fourier_transform). Basically the FFT is an algorithm that allows to carry out the DFT with only ${\cal O}(N \log N)$ operations. To this end it exploits that a DFT of length $N$ can be expressed using two DFTs of length $\frac{N}{2}$. Using a recursion scheme one then ends up at ${\cal O}(N \log N)$.
"

# ╔═╡ 15c95f18-8950-4407-81cc-c7706ad5ee54
note(md"In this lecture we do not explain the FFT itself. If you have not seen a derivation of the FFT we strongly encourage you to investigate the topic. For the remaining of this lecture we  use the FFT as a black-box algorithm though.")

# ╔═╡ 437d293f-23a1-491d-970b-3d51fe0262fe
md"### 6.8.4 FFT based Convolution

With the knowledge of the arithmetic complexity of the FFT we can now think about the cost of an FFT based convolution. It requires ${\cal O}(N \log N)$ for going into the Fourier space, ${\cal O}(N)$ for applying the filter (scalar-wise multiplication) and ${\cal O}(N \log N)$ for going back into image domain. In sum this is still only ${\cal O}(N \log N)$. Thus, an FFT based convolution can be much faster than a directly evaluated convolution, which costs ${\cal O}(N^2)$.

However, in practice the image and the kernel are not always of the same size but the kernel is much smaller. In these cases an image-domain implementation can actually be faster than a Fourier-based implementation. Sophisticated libraries like [ImageFiltering.jl](https://juliaimages.org/ImageFiltering.jl/stable/) implement both and automatically chose based on the kernel size, which strategy to chose (see documentation).


"

# ╔═╡ b26cd8fe-e335-4416-ade9-6c5f757b87e4
md"## 6.9 Wrapup

* Fourier representation of signals allows for a better understanding of filtering.
* Sampling artifacts can be explained and resolved using Fourier analysis.
* Filtering can be more efficiently applied in Fourier space.
* Understanding the the difference between continuous and discrete Fourier transformations is crutial for dealing with them in practice.

"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CoordinateTransformations = "150eb455-5306-5404-9cee-2592286d6298"
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
ImageContrastAdjustment = "f332f351-ec65-5f6a-b3d1-319c6670881a"
ImageTransformations = "02fcd773-0e25-5acc-982a-7f6622650795"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Interpolations = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Noise = "81d43f40-5267-43b7-ae1c-8b967f377efa"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Rotations = "6038ab10-8711-5258-84ad-4b1120ba62dc"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
TestImages = "5e47fb64-e119-507b-a336-dd2b206d9990"

[compat]
CoordinateTransformations = "~0.6.3"
DSP = "~0.7.9"
FFTW = "~1.7.1"
ImageContrastAdjustment = "~0.3.12"
ImageTransformations = "~0.10.0"
Images = "~0.26.0"
Interpolations = "~0.14.7"
Noise = "~0.3.3"
Plots = "~1.39.0"
PlutoUI = "~0.7.54"
Rotations = "~1.6.1"
TestImages = "~1.8.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "fb87c0e2628dae416e20cf71be00a274e145a5ca"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cde29ddf7e5726c9fb511f340244ea3481267608"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.Aqua]]
deps = ["Compat", "Pkg", "Test"]
git-tree-sha1 = "49b1d7a9870c87ba13dc63f8ccfcf578cb266f95"
uuid = "4c88cf16-eb10-579e-8560-4a9242c79595"
version = "0.8.9"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "c5aeb516a84459e0318a02507d2261edad97eb75"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.7.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "492681bc44fac86804706ddb37da10880a2bd528"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.10.4"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "f21cfd4950cb9f0587d5067e69405ad2acd27b87"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.6"

[[deps.BlockArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra"]
git-tree-sha1 = "d434647f798823bcae510aee0bc0401927f64391"
uuid = "8e7c35d0-a365-5155-bbbb-fb81a777f24e"
version = "1.1.1"

    [deps.BlockArrays.extensions]
    BlockArraysBandedMatricesExt = "BandedMatrices"

    [deps.BlockArrays.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "8873e196c2eb87962a2048b3b8e08946535864a1"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+2"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "5a97e67919535d6841172016c9530fd69494e5ec"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.6"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "009060c9a6168704143100f36ab08f06c2af4642"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.2+1"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "3e4b134270b372f2ed4d4d0e936aabaefc1802bc"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "05ba0d07cd4fd8b7a39541e31a7b0254704ea581"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.13"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "9ebb045901e9bbf58767a9f34ff89831ed711aae"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.7"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "c785dfb1b3bfddd1da557e861b919819b82bbe5b"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.27.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.CommonWorldInvalidations]]
git-tree-sha1 = "ae52d1c52048455e85a387fbee9be553ec2b68d0"
uuid = "f70d9fcc-98c5-4d4a-abd7-e4cdeebd8ca8"
version = "1.0.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "ea32b83ca4fefa1768dc84e504cc0a94fb1ab8d1"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.2"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "f9d7112bfff8a19a3a4ea4e03a8e6a91fe8456bf"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.3"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

[[deps.DSP]]
deps = ["Compat", "FFTW", "IterTools", "LinearAlgebra", "Polynomials", "Random", "Reexport", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "0df00546373af8eee1598fb4b2ba480b1ebe895c"
uuid = "717857b8-e6f2-59f4-9121-6e50c889abd2"
version = "0.7.10"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fc173b380865f70627d7dd1190dc2fce6cc105af"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.14.10+0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c6317308b9dc757616f0b5cb379db10494443a7"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.2+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "53ebe7511fa11d33bec688a9178fac4e49eeee00"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.2"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "ec22cbbcd01cba8f41eecd7d44aac1f23ee985e3"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.7.2"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4d81ed14783ec49ce9f2e168208a12ce1815aa25"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "62ca0547a14c57e98154423419d8a342dca75ca9"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.4"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

    [deps.FillArrays.weakdeps]
    PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1ed150b39aebcc805c26b93a8d0122c940f64ce2"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.14+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "532f9126ad901533af1d4f5c198867227a7bb077"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+1"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "8e2d86e06ceb4580110d9e716be26658effc5bfd"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.8"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "da121cbdc95b065da07fbb93638367737969693f"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.8+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "43ba3d3c82c18d88471cfd2924931658838c9d8f"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.0+4"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0224cce99284d997f6880a42ef715a37c99338d1"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.2+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "674ff0db93fffcd11a3573986e550d66cd4fd71f"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.5+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "a641238db938fff9b2f60d08ed9030387daf428c"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.3"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "1dc470db8b1131cfc7fb4c115de89fe391b9e780"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.12.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "1336e07ba2eb75614c99496501a8f4b233e9fafe"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.10"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "401e4f3f30f43af2c8478fc008da50096ea5240f"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.3.1+0"

[[deps.HistogramThresholding]]
deps = ["ImageBase", "LinearAlgebra", "MappedArrays"]
git-tree-sha1 = "7194dfbb2f8d945abdaf68fa9480a965d6661e69"
uuid = "2c695a8d-9458-5d45-9878-1b8a99cf7853"
version = "0.3.1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "8e070b599339d622e9a081d17230d74a5c473293"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.17"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "e12629406c6c4442539436581041d372d69c55ba"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.12"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageBinarization]]
deps = ["HistogramThresholding", "ImageCore", "LinearAlgebra", "Polynomials", "Reexport", "Statistics"]
git-tree-sha1 = "33485b4e40d1df46c806498c73ea32dc17475c59"
uuid = "cbc4b850-ae4b-5111-9e64-df94c024a13d"
version = "0.3.1"

[[deps.ImageContrastAdjustment]]
deps = ["ImageBase", "ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "eb3d4365a10e3f3ecb3b115e9d12db131d28a386"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.12"

[[deps.ImageCore]]
deps = ["Aqua", "BlockArrays", "ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "661ca04f8df633e8a021c55a22e96cf820220ede"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.4"

[[deps.ImageCorners]]
deps = ["ImageCore", "ImageFiltering", "PrecompileTools", "StaticArrays", "StatsBase"]
git-tree-sha1 = "24c52de051293745a9bad7d73497708954562b79"
uuid = "89d5987c-236e-4e32-acd0-25bd6bd87b70"
version = "0.1.3"

[[deps.ImageDistances]]
deps = ["Distances", "ImageCore", "ImageMorphology", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "08b0e6354b21ef5dd5e49026028e41831401aca8"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.17"

[[deps.ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "PrecompileTools", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "432ae2b430a18c58eb7eca9ef8d0f2db90bc749c"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.8"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils"]
git-tree-sha1 = "c5c5478ae8d944c63d6de961b19e6d3324812c35"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.4.0"

[[deps.ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "fa01c98985be12e5d75301c4527fff2c46fa3e0e"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "7.1.1+1"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.ImageMorphology]]
deps = ["DataStructures", "ImageCore", "LinearAlgebra", "LoopVectorization", "OffsetArrays", "Requires", "TiledIteration"]
git-tree-sha1 = "6f0a801136cb9c229aebea0df296cdcd471dbcd1"
uuid = "787d08f9-d448-5407-9aad-5290dd7ab264"
version = "0.4.5"

[[deps.ImageQualityIndexes]]
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "LazyModules", "OffsetArrays", "PrecompileTools", "Statistics"]
git-tree-sha1 = "783b70725ed326340adf225be4889906c96b8fd1"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.7"

[[deps.ImageSegmentation]]
deps = ["Clustering", "DataStructures", "Distances", "Graphs", "ImageCore", "ImageFiltering", "ImageMorphology", "LinearAlgebra", "MetaGraphs", "RegionTrees", "SimpleWeightedGraphs", "StaticArrays", "Statistics"]
git-tree-sha1 = "3ff0ca203501c3eedde3c6fa7fd76b703c336b5f"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.8.2"

[[deps.ImageShow]]
deps = ["Base64", "ColorSchemes", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "3b5344bcdbdc11ad58f3b1956709b5b9345355de"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.8"

[[deps.ImageTransformations]]
deps = ["AxisAlgorithms", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "e0884bdf01bbbb111aea77c348368a86fb4b5ab6"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.10.1"

[[deps.Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageBinarization", "ImageContrastAdjustment", "ImageCore", "ImageCorners", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "12fdd617c7fe25dc4a6cc804d657cc4b2230302b"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.26.1"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0936ba688c6d201805a83da835b55c61a180db52"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.11+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "b842cbff3f44804a84fda409745cc8f04c029a20"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.6"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "10bd689145d2c3b2a9844005d01087cc1194e79e"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.2.1+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "PrecompileTools", "Requires", "TranscodingStreams"]
git-tree-sha1 = "a0746c21bdc986d0dc293efa6b1faee112c37c28"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.53"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "39d64b09147620f5ffbf6b2d3255be3c901bec63"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.8"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "be3dc50a92e5a386872a493a10050136d4703f9b"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "fa6d0bcff8583bac20f1ffa708c3913ca605c611"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.5"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "25ee0be4d43d0269027024d75a24c24d6c6e590c"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.4+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "78211fb6cbc872f77cad3fc0b6cf647d923f4929"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "854a9c268c43b77b0a27f22d7fab8d33cdb3a731"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+1"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "ce5f5621cac23a86011836badfedf664a612cee4"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.5"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "a9eaadb366f5493a5654e843864c13d8b107548c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.17"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "8be878062e0ffa2c3f67bb58a595375eda5de80b"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.11.0+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c6ce1e19f3aec9b59186bdf06cdf3c4fc5f5f3e6"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.50.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "61dfdba58e585066d8bce214c5a51eaa0539f269"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "8084c25a250e00ae427a379a5b607e7aed96a2dd"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.171"

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.LoopVectorization.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "f046ccd0c6db2832a9f639e2c669c6fe867e5f4f"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "1130dbe1d5276cb656f6e1094ce97466ed700e5a"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.7.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "3cebfc94a0754cc329ebc3bab1e6c89621e791ad"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.20"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Noise]]
deps = ["ImageCore", "PoissonRandom", "Random"]
git-tree-sha1 = "d34a07459e1ebdc6b551ecb28e3c19993f544d91"
uuid = "81d43f40-5267-43b7-ae1c-8b967f377efa"
version = "0.3.3"

[[deps.OffsetArrays]]
git-tree-sha1 = "1a27764e945a152f7ca7efa04de513d473e9542e"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.14.1"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "8292dd5c8a38257111ada2174000a33745b06d4e"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.2.4+0"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "76374b6e7f632c130e78100b166e5a48464256f8"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.4.0+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ad31332567b189f508a3ea8957a2640b1147ab00"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.23+1"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "67186a2bc9a90f9f85ff3cc8277868961fb57cbd"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.3"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e127b609fb9ecba6f201ba7ab753d5a605d53801"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.54.1+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "ccee59c6e48e6f2edf8a5b64dc817b6729f99eb5"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.39.0"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PoissonRandom]]
deps = ["Random"]
git-tree-sha1 = "a0f1159c33f846aa77c3f30ebbc69795e5327152"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.4"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "1a9cfb2dc2c2f1bd63f1906d72af39a79b49b736"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.0.11"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsFFTWExt = "FFTW"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "8f6bc219586aef8baf0ff9a5fe16ee9c70cb65e4"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "8b3fc30bc0390abdce15f8822c889f669baed73d"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.1"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "994cc27cdacca10e68feb291673ec3a76aa2fae9"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.6"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays"]
git-tree-sha1 = "1867f44fb5fbeb6ef544ea2b1a8e22882058d30b"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.6.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "52af86e35dd1b177d051b12681e1c581f53c281b"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "456f610ca2fbd1c14f5fcf31c6bfadc55e7d66e0"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.43"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays"]
git-tree-sha1 = "4b33e0e081a825dbfaf314decf58fa47e53d6acb"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.4.0"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2f5d4697f21388cbe1ff299430dd169ef97d7e14"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.4.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "83e6cce8324d49dfaf9ef059227f91ed4441a8e5"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.2"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["CommonWorldInvalidations", "IfElse", "PrecompileTools"]
git-tree-sha1 = "87d51a3ee9a4b0d2fe054bdd3fc2436258db2603"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "1.1.1"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Static"]
git-tree-sha1 = "96381d50f1ce85f2663584c8e886a6ca97e60554"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.8.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "777657803913ffc7e8cc20f0fd04b634f871af8f"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.8"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.StringDistances]]
deps = ["Distances", "StatsAPI"]
git-tree-sha1 = "5b2ca70b099f91e54d98064d5caf5cc9b541ad06"
uuid = "88034a9c-02f8-509d-84a9-84ec65e18404"
version = "0.11.3"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TestImages]]
deps = ["AxisArrays", "ColorTypes", "FileIO", "ImageIO", "ImageMagick", "OffsetArrays", "Pkg", "StringDistances"]
git-tree-sha1 = "0567860ec35a94c087bd98f35de1dddf482d7c67"
uuid = "5e47fb64-e119-507b-a336-dd2b206d9990"
version = "1.8.0"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "0248b1b2210285652fbc67fd6ced9bf0394bcfec"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.1"

[[deps.TiledIteration]]
deps = ["OffsetArrays", "StaticArrayInterface"]
git-tree-sha1 = "1176cc31e867217b06928e2f140c90bd1bc88283"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.5.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d95fe458f26209c66a187b1114df96fd70839efd"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.21.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "4ab62a49f1d8d9548a1c8d1a75e5f55cf196f64e"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.71"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "5f24e158cf4cee437052371455fe361f526da062"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.6"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "6a451c6f33a176150f315726eba8b92fbfdb9ae7"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.4+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "555d1076590a6cc2fdee2ef1469451f872d8b41b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+1"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "936081b536ae4aa65415d869287d43ef3cb576b2"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.53.0+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1827acba325fdcdf1d2647fc8d5301dd9ba43a9d"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.9.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "b70c870239dc3d7bc094eb2d6be9b73d27bef280"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.44+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "7dfa0fd9c783d3d0cc43ea1af53d69ba45c447df"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "ccbb625a89ec6195856a50aa2b668a5c08712c94"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.4.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7d0ea0f4895ef2f5cb83645fa689e52cb55cf493"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2021.12.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─b17eb2a9-d801-4828-b0cd-5792527a10d8
# ╟─c16597c4-9cf9-4a7d-966c-6b6b4aa4765b
# ╟─bdae42a3-8dbe-41ec-911a-89b087b26286
# ╟─f9779b2c-79ce-45f8-a3e7-b4977698748d
# ╟─32b546f2-c745-4c32-82f1-2583e8ceb678
# ╟─64365a87-011f-4814-ab8d-c44cb109063b
# ╟─651cbf87-6672-45a7-b845-4b3877f8dad2
# ╟─a841d668-7de4-4187-95bd-611fc57799ef
# ╟─c9497b69-6390-40a7-99bf-7f80f3546350
# ╟─0028ed4f-495d-4f3b-beb5-c4a9f3ceb176
# ╠═965a2685-c1c8-40ad-8de7-191a52c2d79c
# ╟─7f332548-6437-4e7f-92d1-c73eeecec442
# ╟─783e83f4-95f7-4300-8449-b33d282fe303
# ╟─bb489eac-ad51-4529-8069-2fbc47ca682b
# ╟─934023e2-c4bb-462b-8663-b4b48b341944
# ╟─65d5cbb7-eb7e-4724-8444-e65d91c1ed4e
# ╟─05884c26-45e0-4403-9032-dfcb9504b6c9
# ╟─35dbfaf5-26cb-4400-9dc4-00457c0f2d6e
# ╟─8482e6f5-5405-4ddf-b379-908984eb61dc
# ╟─4cc26d05-df6d-4102-89ab-41e0e444ecf7
# ╠═b24d5a7f-2dfe-41f5-94c9-2019d7e8a5e1
# ╟─1e1c74ae-e429-41cd-8926-7cd843a915d2
# ╟─69a85587-3652-4eb0-84f6-4031c181c6ce
# ╟─7cc2f478-dcca-4f3b-af6b-e35d3845296d
# ╟─556807bc-0b10-44e7-be21-047a5828e3c5
# ╟─b491af95-45c1-4a72-8db4-12eeb74d8f85
# ╟─a1d4c03a-4f30-47b1-afaf-7fd7afbf5c52
# ╟─c8b68e02-e078-4ce2-bc60-8d8774f13bc9
# ╟─f3f024e1-7b00-4170-9b0e-c9473795ebeb
# ╟─247459cb-8713-43c6-afe2-88ba385dd663
# ╟─b34e9617-70e3-42d6-aae9-c8f86282c5d0
# ╟─7bbfa928-2f65-40a4-b359-10ed9f73eab8
# ╟─e3f5467d-7e4b-437b-b26e-e297a84d2089
# ╟─913d9ff7-48e0-42c7-8602-cc0374564d47
# ╟─c56cd0be-9f79-431f-a3db-fca51711d0e2
# ╟─a8a82a9b-8ad3-419f-81af-22c881327797
# ╟─f8185fba-a26c-4625-b9a6-2faf657fecef
# ╟─ca7f36ee-3905-4c43-be93-41352cafcc84
# ╟─a15b8d86-57cd-482e-a8f5-2dc276c050f3
# ╟─c5ae33ed-f899-41e6-b332-c62a2a2ded4c
# ╟─846c1486-4715-47d7-9f28-8b5b097eda83
# ╟─4b6f3e71-4fda-4f34-8f90-d753f1a2e4cd
# ╟─92733ef9-df74-47ba-ad25-bb4613c7cc91
# ╟─9c599aed-edf7-4f78-8389-4f4ae7e96f7a
# ╟─9a2a1470-1cbb-481b-97e7-7774c2fc7a01
# ╟─067aba5b-b04f-433c-96ab-bf91e27f2c7b
# ╟─7d4ea770-3fde-4a42-bf58-f624ad52404f
# ╟─728062d1-2f87-4105-97d8-044345278585
# ╟─44ac6be0-054f-4f62-9a5a-bd3d418f083d
# ╟─26699a53-b283-4c2a-a7fb-6e93253be716
# ╟─fb021197-6728-4159-b97e-ac69a3b52588
# ╟─0c6fba8a-e467-41e6-a51a-9add367799f7
# ╟─a31ac49b-1cdc-4e36-98f1-6d71d60cebf7
# ╟─1eaaf3d0-bd36-4a38-a2ed-30d36af21c75
# ╟─5564633f-0c35-46d6-ae5a-c9b66c45d97f
# ╟─4ce37a01-ccc9-435c-9ee6-faa45506f383
# ╟─9e14f910-b158-4e84-9a46-ae6448f4aca6
# ╟─0f417e1a-7f5c-4604-9a3a-96e47fb9217f
# ╟─8d15d864-9dc8-4571-8f2c-f516d1ade95f
# ╟─7a06e3c1-9f6d-4b02-a3c3-853dbdc65673
# ╟─afd4c72f-b0c4-4644-90e9-3c52cf2ab24e
# ╟─392075cb-f6f0-42a2-afa8-9e0681b54faa
# ╟─8f0d3bea-1dba-4c55-bcf1-dec560302a7b
# ╟─fc63bc91-a1d3-477e-94b0-d96cb8ad21f7
# ╟─e1f32eb6-e71e-4849-81f9-c8930b2cc1f7
# ╟─915b35e0-52d7-4e4a-a83b-47050afe8acf
# ╟─30e13d8b-8b92-486b-bb86-992c081248b3
# ╟─f662100a-9852-40d7-bac5-acefdd136ded
# ╟─e282556f-83ff-4c15-9883-9c6ffc6c9864
# ╟─88c1717e-624b-488e-bccc-a913e8772ac4
# ╟─ebb1c1d3-7ab6-408b-bb6e-aeab86e236ab
# ╟─38d9ef3a-27f0-497f-9792-2b62a90b80a4
# ╟─3e917e7b-f08f-4732-8a27-ce84f5573b2d
# ╟─dbec891c-0db4-4e3f-9e8c-bf10c2f8f89b
# ╟─46e6a68c-5300-40b7-98a6-5e94a0aced62
# ╟─4175dc61-6808-453a-85e9-9d115fcc6f65
# ╟─11631d03-7247-4ab1-86d0-95b1d36d349d
# ╟─a4d141a8-d7c5-4889-86b3-d7e0e8de725b
# ╟─678ea624-19cd-415d-89c4-12a14c4be99a
# ╟─77b9b789-1576-40dc-a339-d04382bc7ada
# ╟─12e81120-5824-445b-a96f-8a90eb7621c9
# ╟─8fa138e8-a9bb-45ea-bcaa-5e48308997e9
# ╟─e29a16c1-30a0-464f-aceb-e51122174358
# ╟─df773ebd-5126-417c-84c3-cf1936af0655
# ╟─719ed4b6-3fbf-47e6-bc29-67873db469b7
# ╟─933cd9cb-4068-4eff-a489-82fddb78e9e7
# ╟─527cb421-d698-4346-944e-c638b93c6a1e
# ╟─8acc7807-bc2e-4ba6-b1fd-e3a917876f6e
# ╟─d93e40fc-a458-4926-9a1e-487080fc2464
# ╟─65888ce6-74e8-4584-a90d-4f36a8556368
# ╟─b9fab49f-8ef2-4ffb-82ea-a2f282186dd4
# ╟─93298b79-9b23-4dcf-9d1e-240aff6e520d
# ╟─b9e462c3-4f94-419b-958b-111ab0fc046b
# ╟─09baa409-a102-4fae-bd52-172ccb9503eb
# ╟─76abbf87-368e-4c08-9956-a0d93b2d2984
# ╟─43599259-37fc-4797-bdc7-af9c45c940f1
# ╟─73671150-acea-4cbd-b40a-a83e1b8cbb1a
# ╟─e8f826dc-c20a-4511-8052-34ae45a320d3
# ╟─04cd89f8-c09a-4314-9868-cdca44108a18
# ╟─de83fa97-3326-4430-a8a4-04de3376821d
# ╟─9709cbac-f1b2-45b9-90bc-8d8f9c1df87c
# ╟─af790681-6ef3-4b32-b9ea-ddab47f5de0e
# ╟─cf36d1d9-58aa-488a-bb66-bfc88d0db8a5
# ╟─b22168cc-db0e-40bb-a7dc-e0e3955fb1d6
# ╟─628f9fb0-4edf-4045-8e76-751edbbd0c4d
# ╟─e81e1ce0-9e14-4201-9922-cb8fdd3fb771
# ╠═8f379fb0-e063-4225-bfed-875702f5a37f
# ╠═225ff0e8-9ffc-4721-8c83-5a74dc8c5fbd
# ╟─cb2ef181-d336-4037-a4aa-4a43697f5a6c
# ╠═f3d8e0e6-c114-4f9d-a4c8-05c02b2d35d9
# ╠═d4ab346c-4c01-4fcf-b6e2-c02f20286205
# ╟─b05d5d51-df12-4de0-abda-c41db8be1c75
# ╟─3b64d064-0335-4892-810a-9cb8973854b3
# ╟─13f9a561-4e81-4515-ac72-f7c23a547435
# ╟─154bcfa3-b7b7-403a-99ae-1f3628a021c4
# ╟─b152c693-983f-4a33-a39f-f91d876ea4d7
# ╟─15c95f18-8950-4407-81cc-c7706ad5ee54
# ╟─437d293f-23a1-491d-970b-3d51fe0262fe
# ╟─b26cd8fe-e335-4416-ade9-6c5f757b87e4
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002