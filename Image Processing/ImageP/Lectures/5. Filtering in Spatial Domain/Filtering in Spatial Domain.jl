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

# ╔═╡ 5b18bc89-d4c9-4e8b-a40d-ceca80d8afa3
begin
	using PlutoUI,Images,TestImages,Interpolations,Plots,Random, LinearAlgebra, FFTW, ImageContrastAdjustment, Statistics, Noise, DSP

hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))
	
	PlutoUI.TableOfContents()
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""

# 5. Image Processing - Filtering in the Spatial Domain
[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ e096b765-acde-4b1c-ae7d-15834295f417
md"## 5.1 Basics of Spatial Filtering

We next investigate transformations that are
* linear
* shift-invariant
* taking a neighborhood into account

So in comparison with the intensity based filters we restrict us in one dimension (linearity) but extend us in another dimension (spatial relationships taken into account). Before we dig deeper into this topic we want to have a look what you can do with filtering:
"

# ╔═╡ 192de76b-de37-4220-b7de-54ee0f5da27b
begin
	img = testimage("mandril_gray");
	imgg = imfilter(img, Kernel.gaussian(7));
	imgl = imfilter(img, Kernel.Laplacian());
	
	plot(
		heatmap(Gray.(img), title="original"),
		heatmap(Gray.(imgg*1.0),title="Gaussian"),
		heatmap(Gray.(imgl./maximum(imgl)*4),title="Laplacian"),
		layout=(1,3), size=(800,260)
	)
end

# ╔═╡ fc8cd33f-782c-4d3a-87ac-ed7d0a81a01e
md"You can see that the filtering with a Gaussian kernel leads to a smoothing, whereas the filtering with a Laplacian kernel leads to an image where the edges are highlighted. All this is done by just changing the kernel, which is introduced next."

# ╔═╡ 979c9063-c5a8-42b2-9b7f-a362fcecc4cc
md"
##### Convolution vs Correlation

There are actually two different operations that one associates with filtering. For two images $f,h:\mathbb{Z}^2\rightarrow\Gamma$, the first is called *correlation* and defined as:

$(f \star h)(u,v) = \sum_{y=-L_y}^{L_y} \sum_{x=-L_x}^{L_x} f(u+x,v+y)h(x,y)$

with $L_x,L_y\in \mathbb{N}$. The other one is called *convolution*:

$(f \ast h)(u,v) = \sum_{y=-L_y}^{L_y} \sum_{x=-L_x}^{L_x} f(u-x,v-y)h(x,y)$

It's important to not get them mixed up.

The reason that they are often mixed up is that they are equivalent under certain circumstances: If the kernel $h$ is symmetric (i.e. $h(x,y) = h(-x,-y)$) it holds that

$\begin{align}  (f \ast h)(u,v) =& \sum_{y=-L_y}^{L_y} \sum_{x=-L_x}^{L_x} f(u-x,v-y)h(x,y)  \\
 = &\sum_{y=-L_y}^{L_y} \sum_{x=-L_x}^{L_x} f(u+x,v+y)h(-x,-y) \\
  \overset{h \text{ symm}.}{=} &\sum_{y=-L_y}^{L_y} \sum_{x=-L_x}^{L_x} f(u+x,v+y)h(x,y) \\
=& (f \star h)(u,v)
\end{align}$

"

# ╔═╡ 4fdec35d-4aa7-4201-b655-5b8b9bc32349
md"We will mostly consider the convolution since it needs to be considered when looking at equivalent relations in Fourier space but we note that many/most image processing methods actually consider the correlation as being the filtering operation. For instance you can have a look at the Julia package [ImageFiltering.jl](https://juliaimages.org/ImageFiltering.jl/stable/#Linear-filtering:-noteworthy-features-1) where this is documented."

# ╔═╡ 8b26909f-289d-4191-b6ed-012948244baf
note(md"The term [convolutional neural networks (CNN)](https://en.wikipedia.org/wiki/Convolutional_neural_network) in machine learning frameworks is actually a misnomer since the operation is usually defined as a correlation. In the context of CNNs the kernels are not symmetric since they are optimized value-by-values when training a neural network.")

# ╔═╡ 3938a3e1-9b17-4ca2-badf-bf9f280f0ced
note(md"Filtering is actually a frequency domain concept. Since one can carry out the operation both in the spatial as well as in the frequency domain one calls it filtering in both domains.")

# ╔═╡ b6a4fd40-f7bd-4242-abfa-5874f76dc1fa
md"### 5.1.1 Dimensions"

# ╔═╡ 7a5e6d91-9e75-474e-90aa-cb36c3ec24da
md"The function $h$ that we use in the convolution is usually called the kernel. It is of size $M_x \times M_y = (2L_x+1)\times(2L_y+1)$. The input image $f$ was of size $N_x \times N_y$ where usually $M_x \ll N_x$ and $M_y \ll N_y$.

This brings us to the issue of choosing the size of the output image, i.e. how to choose $u$ and $v$. There are basically three choices.
1. $u=1+L_x, \dots,N_x-L_x,v=1+L_y,\dots,N_y-L_y$ This is the safest choice since it ensures that we do not evaluate $f$ outside of its definition range. The downside is that we shrank the image, which is often not desired.
2. $u=1, \dots,N_x,v=1,\dots,N_y$ This is the standard choice since the output image has the same size as the input image. However, it needs padding (see next section).
3. $u=1-L_x, \dots,N_x+L_x,v=1-L_y,\dots,N_y+L_y$ This option is considered to be the full convolution. It basically puts the kernel outside the image with just one overlapping pixel. Option 3 is what one would expect when comparing discrete and continuous convolution. This option also requires padding.

The following example shows the three choices for example kernels with $N_x=N_y=3$ and $L_x=L_y = 1$ and zero padding.
"

# ╔═╡ 88c2b19b-d021-49e4-8853-e3099418df6e
LocalResource("img/convBoundary.jpg",:width=>600)

# ╔═╡ a3581bde-b84f-452b-a749-e131afa10032
md"""### 5.1.2 Boundary Handling

Padding means that we extend the image $f$ in a meaningful way. There are different  options that we illustrate with a row 
$\boxed{
\begin{array}{c}
    a, b, c, d, e, f 
\end{array}
}$ that has the two border pixels $a$ and $f$ and we need to extend it to the left and to the right.

* **replicate:** The border pixels extend beyond the image boundaries.
$\boxed{
\begin{array}{l|c|r}
  a, a, a, a  &  a, b, c, d, e, f & f, f, f, f
\end{array}
}$
* **circular:** The border pixels wrap around. For instance, indexing beyond the left border returns values starting from the right border.
$\boxed{
\begin{array}{l|c|r}
  c, d, e, f  &  a, b, c, d, e, f & a, b, c, d
\end{array}
}$
* **reflect:** The border pixels reflect relative to a position between pixels. That is, the border pixel is omitted when mirroring.
$\boxed{
\begin{array}{l|c|r}
  e, d, c, b  &  a, b, c, d, e, f & e, d, c, b
\end{array}
}$
* **symmetric:** The border pixels reflect relative to the edge itself.
$\boxed{
\begin{array}{l|c|r}
  d, c, b, a  &  a, b, c, d, e, f & f, e, d, c
\end{array}
}$
* **zero fill:** Fill the values with zero.
$\boxed{
\begin{array}{l|c|r}
  0,0,0,0 &  a, b, c, d, e, f &0,0,0,0
\end{array}
}$
"""

# ╔═╡ 5ca393b8-6029-43e1-9907-00bd5d3f2faf
md"Which one is the best one cannot be answered in general because it depends on the image characteristic itself. If the underlying signal is periodic, the best is to use *circular* boundary handling. Otherwise *reflect/replicate/symmetric* are usually the methods of choice."

# ╔═╡ c422970d-402a-4a61-ba62-944f9e93d207
md"### 5.1.3 Calculation Rules

If we ignore for the moment the special boundary handling and consider the convolution to take place on the entire plane $\mathbb{Z}^2$ (and functions $f$, $g$, $h$ having compact support) the following rules hold:
* commutativity: 
$f\ast g=g\ast f$
* associativity: 
$f\ast (g\ast h)=(f\ast g) \ast h$
* distributivity:
$\displaystyle f\ast (g+h)=(f\ast g)+(f\ast h)$
* associativity with scalar argument: 
$a(f\ast g)=(af)\ast g=f\ast (ag)$ 
* integration
${\displaystyle \int _{\mathbb {R} ^{d}}(f*g)(x)\,dx=\left(\int _{\mathbb {R} ^{d}}f(x)\,dx\right)\left(\int _{\mathbb {R} ^{d}}g(x)\,dx\right)}$
* differentiation
${\frac {\partial }{\partial x_{i}}}(f*g)={\frac {\partial f}{\partial x_{i}}}*g=f*{\frac {\partial g}{\partial x_{i}}}$
"

# ╔═╡ df3ad185-866a-4f0b-aece-0aefba6b6ed2
md"### 5.1.4 Composing Kernels

Quite often it is handy to build complex filters based on more simple ones. If we take the associativity rule it becomes clear that
$(f * h_1) * h_2 = f * (h_1 * h_2) = f * h_\text{combined}$  
where now $h_\text{combined}$ is the combined filter.

**Examples:**

$\begin{pmatrix} 1 & 1 \end{pmatrix} \ast \begin{pmatrix} 1 & 1 \end{pmatrix}  = \begin{pmatrix} 1 & 2 & 1 \end{pmatrix}$


In particular this is handy when building 2D filters based on 1D ones. We can simply combine a $3 \times 1$ and a $1\times 3$ filter like this

$\begin{pmatrix} 1 & 2 & 1 \end{pmatrix} \ast \begin{pmatrix} 1 \\ 2 \\ 1 \end{pmatrix}  = \begin{pmatrix} 1 & 2 & 1 \\ 2 & 4 & 2 \\ 1 & 2 & 1\end{pmatrix}$

This automatically leads to a separable kernel. This is often named a tensor product approach. We note that tensors can also be made without convolution by plain linear algebra:

$\begin{pmatrix} 1 \\ 2 \\ 1 \end{pmatrix} \begin{pmatrix} 1 & 2 & 1 \end{pmatrix} \  = \begin{pmatrix} 1 & 2 & 1 \\ 2 & 4 & 2 \\ 1 & 2 & 1\end{pmatrix}$ 

The difference becomes apparent when considering the 1D example above where the dimension along which it is convolved is larger than 1.

"

# ╔═╡ bbb4bcf4-8bc1-41e0-b455-4c44ed34228f
md"### 5.1.5 Normalizing Kernels

If a kernel does not sum up to 1 one can simply normalize it using

$h_\text{normalized}(x,y) = \frac{h(x,y)}{\displaystyle\sum_{u=-L_x}^{L_x} \sum_{v=-L_y}^{L_y}h(u,v) }.$
"

# ╔═╡ c468af34-20dc-4a9a-81e3-50ae10ade064
md"## 5.2 Smoothing Spatial Filters

A smoothing filter does smooth all sharp elements in an image. This is what happens in photography when using a lens and focussing on a different plane than where the objects are. This effect is exploited to get [depth of field](https://en.wikipedia.org/wiki/Depth_of_field).
"

# ╔═╡ cdcd7701-a1c9-468e-aba7-e797466df929
LocalResource("img/1620px-Dof_blocks_f1_4.jpg", :width=>800)

# ╔═╡ 66e73546-7f0f-4b43-8741-2fe0fcc36c82
md"
In image processing the smoothing filter is used to reduce the noise in an image. Let's assume that two neighboring pixels have the same value $z$ and and additional noise component $\varepsilon$ with a standard deviation of $\eta$ and a Gaussian noise distribution. Then the mean of both is

$\frac{1}{2} (z_1 + \varepsilon_1  + z_2 + \varepsilon_2) = z + \frac{1}{2}(\varepsilon_1  +  \varepsilon_2)= z + \varepsilon_\text{new}.$

One can show that the variance of $\varepsilon_1  +  \varepsilon_2$ is $2\eta^2$ and in turn the standard deviation is $\sqrt{2}\eta$. If we then take the factor $\frac{1}{2}$ into account we see that the standard deviation of $\varepsilon_\text{new}$ is $\frac{\sqrt{2}}{2} = \frac{1}{\sqrt{2}}$. It easy to see that this generalizes to an $\frac{1}{\sqrt{N}}$ law when considering $N$ pixels to be averaged.

The downside of averaging is of course that $z_1$ and $z_2$ are in practice not the same since an image has variations and in turn we distort the image by this operation. What happens is that values are leaking into the neighboring pixels and in turn the spatial resolution is decreased.
"

# ╔═╡ 0b8ca47e-4abe-4632-b31e-1f22fbbaba60
md"### 5.2.1 Box Filter

Let us now switch to concrete smoothing filters. The *box filter*, or *moving average filter* looks like this

$\frac{1}{M} \begin{pmatrix} 1 & \dots& 1 \\ \vdots & \vdots & \vdots \\ 1 & \dots & 1   \end{pmatrix} \in \mathbb{R}^{M_x\times M_y}$
where $M = M_x M_y$. The factor in front of the filter is important to not change the overall intensity of the image. 
"

# ╔═╡ c6002ede-82cc-419e-a786-0fe6924f64a5
begin
	imgpep = Float64.(Gray.(testimage("peppers_gray")))
	imgpepNoise = imgpep .+ randn(size(imgpep)...)*0.3
	
	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepNoise),title="noisy"),
		heatmap(Gray.( imfilter(imgpepNoise, 1/9*ones(3,3))),title="Mx=3"),
		heatmap(Gray.( imfilter(imgpepNoise, 1/5^2*ones(5,5))),title="Mx=5"),
		heatmap(Gray.( imfilter(imgpepNoise, 1/11^2*ones(11,11))),title="Mx=11"),
		heatmap(Gray.( imfilter(imgpepNoise, 1/21^2*ones(21,21))),title="Mx=21"),
		layout=(2,3), size=(800,550)
	)	
end

# ╔═╡ fefba565-efbf-4f88-8ec4-163f510f3edf
md"### 5.2.2 Binomial Filter

The downside of the box filter is that it has a bad frequency characteristic. We will later see that it corresponds in Fourier space to a multiplication with a sinc function, which has a very inhomogeneous frequency profile leading to certain frequencies being completely blocked.

The downside of the box filter can also be discussed in image space: The box filter assigns to the central pixel all pixels in a certain neighborhood. The distance to the central pixel is not taken into account. This is not desired since in that way a corner pixel on an edge of an image have the same influence as the central pixel.
"

# ╔═╡ 041eb89b-81ac-4e4d-aec2-722e102fcf7b
md"
Thus, what we want is to account for the distance to the central pixel, which can be done by introducing weights. To this end we can exploit the binomial coefficients
$\binom nk = \frac{n!}{k!  (n-k)!}$ where $k$ is chosen to be the filter width and $n$ is the running index. With that we obtain filter kernels

$h_\text{binom}^2 =\frac{1}{4} \begin{pmatrix} 1 & 1 \\  1 &  1 \end{pmatrix}, h_\text{binom}^3 = \frac{1}{16} \begin{pmatrix} 1 & 2 & 1 \\ 2 & 4 & 2 \\  1 & 2 & 1 \end{pmatrix},$

$h_\text{binom}^4 =\frac{1}{64} \begin{pmatrix} 1 & 3 & 3 & 1 \\  3 & 9 & 9 & 3  \\  3 & 9 & 9 & 3 \\ 1 & 3 & 3 & 1 \end{pmatrix}, h_\text{binom}^5 = \frac{1}{256} \begin{pmatrix} 1 & 4 & 6 & 4 & 1 \\  4 & 16 & 24 & 16 & 4 \\  6 & 24 & 36 & 24 & 6 \\  4 & 16 & 24 & 16 & 4 \\ 1 & 4 & 6 & 4 & 1 \end{pmatrix}$
"

# ╔═╡ fe4fac22-d3cf-47f9-b81c-1f26972f7f66
md"where we already have applied the tensor product approach to generate 2D filters based on the 1D filters.

It's interesting to note that these filter can in general be derived by combining the binomial filter with itself:

$h^d_\text{binom} =  h^{d-1}_\text{binom} \ast h^{2}_\text{binom}$
"

# ╔═╡ c56b53c4-9778-412d-bf88-666962c98869
md"Let us apply the binomial filter to the noisy data:"

# ╔═╡ ae613067-59f9-4ad0-b49c-167d6eafdc6a
begin
	
	binomial_kernel(m) = [ binomial(m-1,l)*binomial(m-1,k) for l=0:m-1, k=0:m-1] / (2^(2m-2))

	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepNoise),title="noisy"),
		heatmap(Gray.( imfilter(imgpepNoise, binomial_kernel(3))),title="Mx=3"),
		heatmap(Gray.( imfilter(imgpepNoise, binomial_kernel(5))),title="Mx=5"),
		heatmap(Gray.( imfilter(imgpepNoise, binomial_kernel(11))),title="Mx=11"),
		heatmap(Gray.( imfilter(imgpepNoise, binomial_kernel(21))),title="Mx=21"),
		layout=(2,3), size=(800,550)
	)	
end

# ╔═╡ 4bbe370f-d3ff-42f8-bc00-fe82dd3cd6c3
md"One can see that we can choose the kernel much larger now without reducing the spatial resolution too much. But this is more a difference in parameter choice. The differences between both filters are not huge but the binomial filter generates no block artifacts that one can identify for the box filter:"

# ╔═╡ 16496bb7-70eb-48e0-9747-257c9acdd2a8
begin
	plot(
		heatmap(Gray.( imfilter(imgpepNoise, 1/8^2*ones(8,8)))[200:400,100:300],title="Box"),
		heatmap(Gray.( imfilter(imgpepNoise, binomial_kernel(20)))[200:400,100:300],title="Binomial"),
		layout=(1,2), size=(800,400)
	)	
end

# ╔═╡ d4019f55-c819-41ae-b5f7-cb813568f746
md"### 5.2.3 Gaussian Filter

The binomial kernel was a clear improvement compared to the box filter and it has the nice property that in principle it can be performed in integer arithmetic if the factor is applied after the convolution. The drawback is that one has no continuous parameter to adjust the smoothing effect. This brings us to the Gaussian filter that doesn't  have this drawback. It is defined as

$h_\text{Gaussian}^\sigma(x,y) = \frac{1}{2\pi\sigma^2}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right)$

Let's have a look how this function looks like for $\sigma=1.0$ and a profile along the $x$ direction:
"

# ╔═╡ 39b7deca-6377-4959-a1f9-f589faca37a6
begin
	gaussian(x,y,σ) = exp(-(x^2+y^2)/(2*σ^2)) / (2*pi*σ^2)
	x = range(-5,5,length=100)
	
	plot(x, gaussian.(x,0,1.0), lw=2, label="gaussian")
end

# ╔═╡ 0a62fa76-187e-4c20-ae87-db1125a66d7b
md"
What is interesting to note here is that the kernel is infinitely sized, i.e. one needs to sample it and cut of at a certain value. Often a value of $L_x=L_y = 2\sigma$ is chosen in which case the curve has dropped to $\text{exp}(-2) \approx 13.5\%$ of its maximum value.

Since the kernel is cut of, the scaling factor is not valid anymore to let the kernel sum up to 1. Thus one needs to apply the kernel normalization technique discussed earlier. With that we can define the gaussian kernel as"

# ╔═╡ 5ddd421d-7253-4176-bf4c-10b644e67bbd
function gaussian_kernel(σ,m=2σ) 
	h = [ exp(-(x^2+y^2)/(2*σ^2)) for x=-m:m, y=-m:m] 
	return h./sum(vec(h))
end

# ╔═╡ 21f41570-5ab1-4bd9-b340-92decb935572
gaussian_kernel(1.0)

# ╔═╡ e2fb5692-4029-4cd2-90b1-897a3b774fce
md"Note that the **ImageFiltering.jl** package has this and other kernels readily available:"

# ╔═╡ 98578c7e-b6b9-4088-bbfc-a03f01332760
Kernel.gaussian(1.0)

# ╔═╡ 7cb487b8-d12d-4a6c-bebf-327d58cc7d88
md"Let's apply the Gaussian as noise reducing filter:"

# ╔═╡ cf6c5a4c-28b9-4673-98f6-6b963b003264
begin
	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepNoise),title="noisy"),
		heatmap(Gray.( imfilter(imgpepNoise, Kernel.gaussian(2))),title="σ=2"),
		heatmap(Gray.( imfilter(imgpepNoise, Kernel.gaussian(3))),title="σ=3"),
		heatmap(Gray.( imfilter(imgpepNoise, Kernel.gaussian(5))),title="σ=5"),
		heatmap(Gray.( imfilter(imgpepNoise, Kernel.gaussian(7))),title="σ=7"),
		layout=(2,3), size=(800,550)
	)	
end

# ╔═╡ 6ea9a3b6-180d-43f0-942a-1068c6671233
md"
### 5.2.4 Comparison of Filter kernels

The following plot shows the box, binomial and Gaussian kernel in comparison for $M_x=M_y=13$ and $\sigma=1.76$. Below the 2D image a line profile is shown. One can clearly see that the binomial filter matches the Gaussian filter for the chosen $\sigma$.
"




# ╔═╡ aa438aee-8a03-4386-a571-62c85cf02405
begin
  box = zeros(13,13)
  box[5:9,5:9] .= 1/25	

	plot(
	heatmap(box, title="Box"),
	heatmap(binomial_kernel(13), title="Binomial"),
    heatmap(gaussian_kernel(1.76, 6), title="Gaussian"),
	layout=(1,3), size=(800,200)
	)
end

# ╔═╡ 3a95c34c-8da5-47a6-8b14-6c485999f36c
begin
  p9 = plot(binomial_kernel(13)[:,6], label="binomial", lw=2 )	
  plot!(p9, gaussian_kernel(1.76, 6)[:,6], label="Gaussian", lw=2 )	
  plot!(p9, box[:,6], label="Box", lw=2 )
end

# ╔═╡ 91c68ad1-419e-4484-8a15-dde77a9988a8
md"## 5.3 Sliding Window Mapping

The basic idea of convolution-based filtering is to take a small region around a pixel and derive an updated value based on this region. What is essential here, is that the filter kernel does not depend on the actual values within the image region.

When loosening this restriction we can build more powerful methods that take for an image pixel index $\mathbf{r}$ the region $R(\mathbf{r})$ and apply some function $h$ yielding the output image, i.e.

$g(\mathbf{r}) = h(f(R(\mathbf{r})))$

where $f(\mathbf r)$ is the input image. The important difference is that the regular filter does not depend on $f$ but here $h$ depends on $f$.
"

# ╔═╡ 2e6721d2-a369-4d1b-9546-131334ca088c
md"### 5.3.1 Median Filter

The most prominent example of a sliding window mapping is the application of a median. The median can be defined as $\text{median}: \mathbb{R}^N \rightarrow \mathbb{R}$

$\text{median}(\mathbf u) = \begin{cases} \qquad\text{sort}(\mathbf u)_{ \frac{N-1}{2} +1} & \text{if } N \text{ is odd} \\
\frac{1}{2}\left(\text{sort}(\mathbf u)_{ \frac{N}{2} } +\text{sort}(\mathbf u)_{ \frac{N}{2} +1} \right) & \text{if } N \text{ is even} 
\end{cases}$

For instance we have

$\text{median}(\,(1,2,7,9)^T\,) = 4.5$

$\text{median}(\,(1,2,7,9,5000)^T\,) = 7$
"

# ╔═╡ 64f0c72d-1ddc-416c-a9d1-f45ddd78cb06
md" ##### Applications

The median is an alternative to the convolution-based filters discussed before. For uncorrelated Gaussian noise the median filter will not improve the result since the Gaussian filter is tailored towards the noise model.

However, in the case of so-called [salt-and-pepper noise](https://en.wikipedia.org/wiki/Salt-and-pepper_noise) the Gaussian filter works much worse. 

Salt and pepper noise means that the image contains noise in the form of impulses, i.e. strong deviations in individual pixels. This is typical for the case where one has [defective pixels](https://en.wikipedia.org/wiki/Defective_pixel). What happens when applying a Gaussian filter is that the defective pixels is smeared into several neighboring pixels and it can only be removed when using a large kernel width  strongly degrading the spatial resolution.

The median filter, however, can handle salt-and-pepper noise case much better. It orders the pixel and in turn the defective value is very unlikely to be the middle of the sorted array. Instead it will be at the beginning or the end and is filtered out. Here is an example showcasing this:"

# ╔═╡ 4b462937-216b-440b-a9e5-9f53b8805222
begin
	imgblobs = Float64.(Gray.(testimage("blobs")))
	#imgNoise = imgblobs + randn(size(imgblobs)...)*0.2
	imgNoise = salt_pepper(imgblobs, 0.3)
	
	imgMedian = mapwindow(median!, imgNoise, (5,5))
	imgGaussian = imfilter(imgNoise, Kernel.gaussian(2))

	plot(
		heatmap(Gray.(imgblobs), title="original"),
		heatmap(Gray.(imgNoise),title="noisy"),
		heatmap(Gray.(imgGaussian),title="Gaussian"),
		heatmap(Gray.(imgMedian),title="median"),
		layout=(2,2), size=(800,830)
	)	
	
end

# ╔═╡ 44384327-1bae-49fd-ad73-2a1b12f82422
md"## 5.4 Sharpening Spatial Filters

The opposite of a smoothing filter is a sharpening filter. In fact one can think of the two as the inverses of each other. But convolution operations cannot be simply inverted in spatial domain and we will therefore take a more heuristic approach in the spatial domain (inverting will be discussed next lecture).

What is required to make an image more sharp? In fact, a sharp image is characterized by its sharp edges. Thus, image sharpening methods have the goal to highlight edges more. This means, if you have a blurred edge you want to add an image where only the edge is sharply drawn. Thus the idea is consider an approach like this

$f_\text{sharpened}(\mathbf{r}) = f_\text{smooth}(\mathbf{r}) + f_\text{edge}(\mathbf{r})$

where $f_\text{smooth}(\mathbf{r})$ is the original image.
"

# ╔═╡ e68d87e0-5f7d-4df6-bc5e-06b41d6f1813
md"### 5.4.1 Edge Enhancement
We need a filter that enhances the edges of an image. This can be done by applying the spatial derivative. For discrete functions, the spatial derivative is carried out using [finite differences](https://en.wikipedia.org/wiki/Finite_difference), i.e. instead of 

$\frac{\partial f}{\partial x}=\lim _{h\to 0}{\frac {f(x+h)-f(x)}{h}},$

which would be used for a continuous function we use 

$\delta (f)(x)={f(x+1)-f(x)}.$

Similarly, instead of the second derivative, which can be shown to be 

$\frac{\partial^2 f}{\partial^2 x}=\lim _{h\to 0}{\frac {2f(x)-f(x+h)-f(x-h)}{h^2}},$

we can use

$\delta^2 (f)(x)={2f(x)-f(x+1)-f(x-1)}.$

In both cases we exploited that the pixel spacing is $h=1$.

"

# ╔═╡ 43d8dabc-3d48-4e61-b605-b2201765794c
md"Now the question is: What derivative is more appropriate for edge enhancement. Let have a look at the following case study:
"

# ╔═╡ 260ee68f-ecf1-476a-ac08-abe50965740e
let
	imgpepBlurred = imfilter(imgpepNoise, Kernel.gaussian(5))
	
	l=400
	
	p = plot(imgpepBlurred[l,:], lw=2, label="original")
	plot!(p,4*diff(imgpepBlurred[l,:]), lw=2, label="first derivative")
	plot!(p,16*diff(diff(imgpepBlurred[l,:])), lw=2, label="second derivative")
end

# ╔═╡ fbbcba23-e7da-4255-99b6-66dadf2a11a0
md"From this example we can already learn several things:
* The first derivative has a single peak for each edge. This peak appears where the tangent has the maximum rise.
* The second derivative has two peaks: One where the blurred function has the maximum curvature at the beginning and one at the end of the transition.
* Derivatives enhance noise, especially when they are applied multiple times.

From the perspective of edge enhancement we actually do not want to change the image where the strongest rise is but we want to make the transition narrower. Thus, the second derivative is more attractive since it can cancel out exactly those signals where the transition already began because of the artificial blurring in the image.

Let's add the edge enhanced signal to the original signal and see the edge enhancement in action:"

# ╔═╡ ff556383-7826-4622-b384-c21902da8720
let
	imgpepBlurred = imfilter(imgpepNoise, Kernel.gaussian(5))
	
	l=300
	
	p = plot(imgpepBlurred[l,:], lw=2, label="original")
	plot!(p,imgpepBlurred[l,1:(end-2)]-16*diff(diff(imgpepBlurred[l,:])), lw=2, label="edge enhanced")
end

# ╔═╡ f861a2e4-6131-4261-962b-9a509dabc59a
md"
##### Kernel Perspective

Looking at the first and second order difference operator we can see that they can actually can be written as a filters

$h_\text{diff} = \begin{pmatrix} -1 & 1  \end{pmatrix}\quad \text{and} \quad h^2_\text{diff} = \begin{pmatrix} -1 & 2 & -1  \end{pmatrix}$

In fact we have 

$h^2_\text{diff} = h_\text{diff} \ast h_\text{diff}$

what you can also verify in Julia:
"

# ╔═╡ 1b4b9883-3e65-49a6-a8e3-a9b8383290b0
conv([-1,1],[-1,1])

# ╔═╡ f76dfb8e-071c-4dd2-b713-dd1bb620b651
md"
### 5.4.2 Laplace Filter

In 2D images, the direction of edges needs to be taken into account. To this end one can combine the partial derivatives

$\frac{\partial^2 f}{\partial^2 x} \quad \text{and} \quad \frac{\partial^2 f}{\partial^2 y}.$

Let's have a look at the two for an example image:

"

# ╔═╡ 001c6cac-f197-425b-ad09-374379c3d0bf
let
	imgpepBlurred = imfilter(imgpepNoise, Kernel.gaussian(5))
	
	kernel = [-1 2 -1]
	imgpepEdgeX = 100*imfilter(imgpepBlurred, kernel')
	imgpepEdgeY = 100*imfilter(imgpepBlurred, kernel)
	
	plot(
		heatmap(Gray.(imgpepBlurred),title="blurred"),
		heatmap(Gray.(imgpepEdgeX),title="diff x"),
		heatmap(Gray.(imgpepEdgeY),title="diff y"),
		heatmap(Gray.(imgpepEdgeY+imgpepEdgeX),title="diff x+y"),

		layout=(2,2), size=(800,830)
	)	
end

# ╔═╡ cbbb1bf9-10a8-49e0-9652-520d935048f0
md"We can see that $\frac{\partial^2 f}{\partial^2 x}$ enhanced the edges in the $x$ direction while $\frac{\partial^2 f}{\partial^2 y}$ enhances the edges in the other direction. To combine both we can add them, which is known to be the Laplace operator:

$\begin{align} \Delta f &= \frac{\partial^2 f}{\partial^2 x} + \frac{\partial^2 f}{\partial^2 y} \\
&=  \nabla \cdot \nabla f \\
&=  \nabla^2 f 
\end{align}$

where $\nabla f=\left({\frac {\partial f}{\partial x}},{\frac {\partial f}{\partial y}}\right)^T$ is the gradient of the image.
"

# ╔═╡ 96ddb58b-4cbe-4d9e-bf4b-e86d0ef8c27e
md"Translating this to the discrete setting we thus obtain the Laplacian kernel

$h_\text{Laplacian} = \begin{pmatrix} 0 & -1 & 0 \\ 0 & 2 & 0 \\ 0 & -1 & 0\end{pmatrix} + \begin{pmatrix} 0 & 0 & 0 \\ -1 & 2 & -1 \\ 0 & 0 & 0\end{pmatrix} = \begin{pmatrix} 0 & -1 & 0 \\ -1 & 4 & -1 \\ 0 & -1 & 0\end{pmatrix}$

In practice, this kernel is only isotropic when considering 90$^\circ$ angles. To also take 45$^\circ$ angles into account one can  define a rotated Laplacian

$h^{45^\circ}_\text{Laplacian} =  \begin{pmatrix} -1 & 0 & -1 \\ 0 & 4 & 0 \\ -1 & 0 & -1\end{pmatrix}$ 

which can be added to the regular one:

$h^{\text{isotropic}}_\text{Laplacian} = h_\text{Laplacian} + h^{45^\circ}_\text{Laplacian} =   \begin{pmatrix} -1 & -1 & -1 \\ -1 & 8 & -1 \\ -1 & -1 & -1\end{pmatrix}$ 
"

# ╔═╡ 5d39f70a-d403-4bfd-a4b1-beeb999b15bc
md"##### Combining with Smooth Image

Recall that we aimed for combining the smoothed image with the edge image in an additive manner. With our knowledge about the Laplace operator we can express this in continuous notation as 

$f_\text{sharpened}(\mathbf{r}) = f_\text{smooth}(\mathbf{r}) + \alpha \Delta f_\text{smooth} (\mathbf{r})$

Here, the parameter $\alpha$ is used to weight the edge image. This allows us to control, how sharp the edges should get. If $\alpha$ is chosen too low the image is still blurred. If it is chosen too large the edges are over-expressed and the entire image contains more noise artifacts.
"

# ╔═╡ 541fa723-552f-49d7-9c56-4c66a5947485
note(md"When using the parameter $\alpha$ the operation is also known as [unsharp masking](https://en.wikipedia.org/wiki/Unsharp_masking) and used in the printing and publishing industry since the 1930s  to
sharpen images.")

# ╔═╡ 3c507d61-5679-446e-9437-a1c3cfb0cbb3
md"The following shows unsharp masking in action. You can also change the value of α using this slider $(@bind α1 Slider(1:100; default=10, show_value=true))"

# ╔═╡ 89d621c1-436e-4837-903d-2bb05bd8a77f
let
	imgpepBlurred = imfilter(imgpepNoise, ImageFiltering.Kernel.gaussian(5))
	
	kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1]
	imgpepEdge = imfilter(imgpepBlurred, kernel)
	
	sharpen(f, α) = f + α* imfilter(f, kernel)
	
	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepBlurred),title="blurred"),
		heatmap(Gray.(3*imgpepEdge./maximum(imgpepEdge)),title="edge"),
		
		heatmap(Gray.(sharpen(imgpepBlurred,1.0)),title="sharpened α=1"),
		heatmap(Gray.(sharpen(imgpepBlurred,5.0)),title="sharpened α=5"),
		heatmap(Gray.(sharpen(imgpepBlurred,α1)),title="sharpened α=$α1"),

		layout=(2,3), size=(800,550)
	)	
end

# ╔═╡ f77bf7e2-8429-4859-8a56-64e0c7139785
md"How does the kernel $h_\text{sharpened}^\alpha$ look like?"

# ╔═╡ bd8d781d-2670-42bc-98a0-2e7b95a66060
md"$\begin{align} h_\text{sharpened}^\alpha &= h_\text{identity} + \alpha h^{\text{isotropic}}_\text{Laplacian} \\
&= \begin{pmatrix} 0 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 0\end{pmatrix} + \alpha\begin{pmatrix} -1 & -1 & -1 \\ -1 & 8 & -1 \\ -1 & -1 & -1\end{pmatrix} \\
& = \begin{pmatrix} -\alpha & -\alpha & -\alpha \\ -\alpha & 1+\alpha8 & -\alpha \\ -\alpha & -\alpha & -\alpha\end{pmatrix}
\end{align}$"

# ╔═╡ e8bf93ea-00dd-4166-82d7-7922de27731c
md"### 5.4.3 Laplacian of Gaussian

One issue of the edge image is that it increases the noise. In order to suppress the noise one can instead:
* First, smooth the image using a Gaussian filter, which reduces the noise.
* Then, apply the edge enhancement filter.
This is known as the [Laplacian of Gaussian](https://de.wikipedia.org/wiki/Marr-Hildreth-Operator) short LoG.
Let's first have a look at this filter:
"

# ╔═╡ 573721e6-29f2-4fb7-84be-2433115e9e32
plot(heatmap(collect(-Kernel.LoG(10)),c=:viridis,cb=nothing),
	 plot(collect(-Kernel.LoG(10)),c=:viridis,st=:surface, cb=nothing), size=(800,400)
	)

# ╔═╡ 38134ff0-e7a1-4875-a5b4-512b71d1229a
md"Because this looks like a [sombrero](https://en.wikipedia.org/wiki/Mexican_hat), the filter is also known as the maxican hat filter."

# ╔═╡ 635df2b8-dc26-41bc-b422-4cd0437b48a1
md"
Mathematically we can write the LoG in a continuous form as

$\Delta ( f(x,y) \ast h_\text{Gaussian}^\sigma )$

But instead due to the differentiation rule of the convolution we can write this as

$f(x,y) \ast (\Delta  h_\text{Gaussian}^\sigma )$

This has the advantage that we can derive the kernel $h_\text{LoG}$ analytically:

$\begin{align} h_\text{LoG} & = \frac{\partial^2 h_\text{Gaussian}^\sigma(x,y)}{\partial^2 x} + \frac{\partial^2 h_\text{Gaussian}^\sigma(x,y)}{\partial^2 y} \\
& = \frac{\partial^2}{\partial^2 x} \frac{1}{2\pi\sigma^2}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right)   +  \frac{\partial^2}{\partial^2 y}  \frac{1}{2\pi\sigma^2}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) \\
& = \frac{\partial}{\partial x} \frac{-x}{2\pi\sigma^4}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right)   + \frac{\partial}{\partial y} \frac{-y}{2\pi\sigma^4}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right)  \\
& = \frac{x^2}{2\pi\sigma^6}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) - \frac{1}{2\pi\sigma^4}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) + \\
& \quad \frac{y^2}{2\pi\sigma^6}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) - \frac{1}{2\pi\sigma^4}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) \\
& = -\frac{1}{\pi\sigma^4}\text{exp}\left(-\frac{x^2+y^2}{2\sigma^2} \right) \left(  1  - \frac{x^2+y^2}{2\sigma^2} \right)\\
\end{align}$


"

# ╔═╡ 1873b8ca-d25f-4d06-aa9d-4e771200c4c7
md"We can use the LoG for image sharpening. Then we have two parameters 

σ $(@bind σ_ Slider(1:30; default=10, show_value=true)) and α $(@bind α_ Slider(range(1,10,length=100)*0.1; default=0.1, show_value=true))"

# ╔═╡ 3bb3b116-00de-46d6-bccd-2768a6940a37
let
	imgpepBlurred = imfilter(imgpepNoise, Kernel.gaussian(5))
	
	imgpepEdge = imfilter(imgpepBlurred, Kernel.LoG(σ_))

	imgpepSharpened = imgpepBlurred - α_/maximum(imgpepEdge)*imgpepEdge
	
	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepBlurred),title="blurred"),
		heatmap(Gray.(imgpepEdge ./ maximum(imgpepEdge)),title="edge"),
		heatmap(Gray.(imgpepSharpened),title="sharpened"),

		layout=(2,2), size=(800,830)
	)	
end

# ╔═╡ 5e0d247d-e913-45c0-bdd1-dd0dc97dfde7
md"## 5.5 Wrapup

In this lecture we have introduced spatial filtering as a tool for image enhancement. Both image smoothing and image sharpening filters have been discussed. In practice one often applies a combination of several filter, which can be  done be applying the filter sequentially.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
ImageContrastAdjustment = "f332f351-ec65-5f6a-b3d1-319c6670881a"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Interpolations = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Noise = "81d43f40-5267-43b7-ae1c-8b967f377efa"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
TestImages = "5e47fb64-e119-507b-a336-dd2b206d9990"

[compat]
DSP = "~0.7.9"
FFTW = "~1.7.1"
ImageContrastAdjustment = "~0.3.12"
Images = "~0.26.0"
Interpolations = "~0.14.7"
Noise = "~0.3.3"
Plots = "~1.39.0"
PlutoUI = "~0.7.53"
TestImages = "~1.8.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "8515e6c640d6348110481f7cc4cbf685baa91a1a"

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
git-tree-sha1 = "13951eb68769ad1cd460cdb2e64e5e95f1bf123d"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.27.0"

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
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

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
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

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
git-tree-sha1 = "bc3f416a965ae61968c20d0ad867556367f2817d"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.9"

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
git-tree-sha1 = "2e4520d67b0cef90865b3ef727594d2a58e0e1f8"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.11"

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
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "b2a7eaa169c13f5bcae8131a83bc30eff8f71be0"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.2"

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
git-tree-sha1 = "355e2b974f2e3212a75dfb60519de21361ad3cb7"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.9"

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
git-tree-sha1 = "be8e690c3973443bec584db3346ddc904d4884eb"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.5"

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
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

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
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

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
git-tree-sha1 = "5680a9276685d392c87407df00d57c9924d9f11e"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.7.1"
weakdeps = ["RecipesBase"]

    [deps.Rotations.extensions]
    RotationsRecipesBaseExt = "RecipesBase"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "98ca7c29edd6fc79cd74c61accb7010a4e7aee33"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.6.0"

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
git-tree-sha1 = "6ee0c220d0aecad18792c277ae358129cc50a475"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.0"

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
git-tree-sha1 = "f1f6d497ff84039deeb37f264396dac0c2250497"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.2"

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
# ╟─5b18bc89-d4c9-4e8b-a40d-ceca80d8afa3
# ╟─e096b765-acde-4b1c-ae7d-15834295f417
# ╟─192de76b-de37-4220-b7de-54ee0f5da27b
# ╟─fc8cd33f-782c-4d3a-87ac-ed7d0a81a01e
# ╟─979c9063-c5a8-42b2-9b7f-a362fcecc4cc
# ╟─4fdec35d-4aa7-4201-b655-5b8b9bc32349
# ╟─8b26909f-289d-4191-b6ed-012948244baf
# ╟─3938a3e1-9b17-4ca2-badf-bf9f280f0ced
# ╟─b6a4fd40-f7bd-4242-abfa-5874f76dc1fa
# ╟─7a5e6d91-9e75-474e-90aa-cb36c3ec24da
# ╟─88c2b19b-d021-49e4-8853-e3099418df6e
# ╟─a3581bde-b84f-452b-a749-e131afa10032
# ╟─5ca393b8-6029-43e1-9907-00bd5d3f2faf
# ╟─c422970d-402a-4a61-ba62-944f9e93d207
# ╟─df3ad185-866a-4f0b-aece-0aefba6b6ed2
# ╟─bbb4bcf4-8bc1-41e0-b455-4c44ed34228f
# ╟─c468af34-20dc-4a9a-81e3-50ae10ade064
# ╟─cdcd7701-a1c9-468e-aba7-e797466df929
# ╟─66e73546-7f0f-4b43-8741-2fe0fcc36c82
# ╟─0b8ca47e-4abe-4632-b31e-1f22fbbaba60
# ╟─c6002ede-82cc-419e-a786-0fe6924f64a5
# ╟─fefba565-efbf-4f88-8ec4-163f510f3edf
# ╟─041eb89b-81ac-4e4d-aec2-722e102fcf7b
# ╟─fe4fac22-d3cf-47f9-b81c-1f26972f7f66
# ╟─c56b53c4-9778-412d-bf88-666962c98869
# ╟─ae613067-59f9-4ad0-b49c-167d6eafdc6a
# ╟─4bbe370f-d3ff-42f8-bc00-fe82dd3cd6c3
# ╟─16496bb7-70eb-48e0-9747-257c9acdd2a8
# ╟─d4019f55-c819-41ae-b5f7-cb813568f746
# ╟─39b7deca-6377-4959-a1f9-f589faca37a6
# ╟─0a62fa76-187e-4c20-ae87-db1125a66d7b
# ╠═5ddd421d-7253-4176-bf4c-10b644e67bbd
# ╠═21f41570-5ab1-4bd9-b340-92decb935572
# ╟─e2fb5692-4029-4cd2-90b1-897a3b774fce
# ╠═98578c7e-b6b9-4088-bbfc-a03f01332760
# ╟─7cb487b8-d12d-4a6c-bebf-327d58cc7d88
# ╟─cf6c5a4c-28b9-4673-98f6-6b963b003264
# ╟─6ea9a3b6-180d-43f0-942a-1068c6671233
# ╟─aa438aee-8a03-4386-a571-62c85cf02405
# ╟─3a95c34c-8da5-47a6-8b14-6c485999f36c
# ╟─91c68ad1-419e-4484-8a15-dde77a9988a8
# ╠═2e6721d2-a369-4d1b-9546-131334ca088c
# ╟─64f0c72d-1ddc-416c-a9d1-f45ddd78cb06
# ╟─4b462937-216b-440b-a9e5-9f53b8805222
# ╟─44384327-1bae-49fd-ad73-2a1b12f82422
# ╟─e68d87e0-5f7d-4df6-bc5e-06b41d6f1813
# ╟─43d8dabc-3d48-4e61-b605-b2201765794c
# ╟─260ee68f-ecf1-476a-ac08-abe50965740e
# ╟─fbbcba23-e7da-4255-99b6-66dadf2a11a0
# ╟─ff556383-7826-4622-b384-c21902da8720
# ╟─f861a2e4-6131-4261-962b-9a509dabc59a
# ╠═1b4b9883-3e65-49a6-a8e3-a9b8383290b0
# ╟─f76dfb8e-071c-4dd2-b713-dd1bb620b651
# ╟─001c6cac-f197-425b-ad09-374379c3d0bf
# ╟─cbbb1bf9-10a8-49e0-9652-520d935048f0
# ╟─96ddb58b-4cbe-4d9e-bf4b-e86d0ef8c27e
# ╟─5d39f70a-d403-4bfd-a4b1-beeb999b15bc
# ╟─541fa723-552f-49d7-9c56-4c66a5947485
# ╟─3c507d61-5679-446e-9437-a1c3cfb0cbb3
# ╟─89d621c1-436e-4837-903d-2bb05bd8a77f
# ╟─f77bf7e2-8429-4859-8a56-64e0c7139785
# ╟─bd8d781d-2670-42bc-98a0-2e7b95a66060
# ╟─e8bf93ea-00dd-4166-82d7-7922de27731c
# ╟─573721e6-29f2-4fb7-84be-2433115e9e32
# ╟─38134ff0-e7a1-4875-a5b4-512b71d1229a
# ╟─635df2b8-dc26-41bc-b422-4cd0437b48a1
# ╟─1873b8ca-d25f-4d06-aa9d-4e771200c4c7
# ╟─3bb3b116-00de-46d6-bccd-2768a6940a37
# ╟─5e0d247d-e913-45c0-bdd1-dd0dc97dfde7
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
