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
	using PlutoUI, Images,TestImages, Plots, LinearAlgebra, Interpolations, ImageTransformations,CoordinateTransformations, Rotations, Printf

	
hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))	
	
	PlutoUI.TableOfContents(depth=4)
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""
# Image Processing - Image Fundamentals

[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ 4ddfffe8-60f4-437f-b3ff-3c10820ac249
md"
## 1. Mathematical Notation

In this course we use standard mathematical notation where small boldface letters denote vectors and capital boldface letters denote matrices. Moreover, we use the symbol $^*$ to denote complex conjugation of either a scalar, vector or a matrix. In the case of a vector or matrix, complex-conjugation is understood to be performed component-wise. For a matrix $\textbf{A}$, we use $\textbf{A}^\mathsf{T}$ to denote the transposed matrix and $\textbf{A}^\mathsf{H} = (\textbf{A}^*)^\mathsf{T}$ to denote the complex-conjugated and transposed matrix. For a vector $\textbf{x}\in\mathbb{R}^N$, the transposed vector $\textbf{x}^\mathsf{T}$ refers to the corresponding row vector obtained when interpreting $\textbf{x}$ as a $(N\times 1)$-matrix.
"

# ╔═╡ 468ad103-3cea-4860-b6d7-6e267f8ba0d9
md"For two vectors or matrices, the Hadamard product is defined as

$\begin{equation}
\mathbf{A}  \odot \mathbf{B} = 
\begin{pmatrix} 
a_{1,1} \cdot b_{1,1} & \cdots & a_{1,N} \cdot b_{1,N} \\
\vdots & \ddots & \vdots \\ 
a_{M,1} \cdot b_{M,1} & \cdots & a_{M,N} \cdot b_{M,N} 
\end{pmatrix}
\end{equation}$

The Hadamard division is defined as

$\begin{equation}
\mathbf{A}  \oslash \mathbf{B} = 
\begin{pmatrix} 
a_{1,1} / b_{1,1} & \cdots & a_{1,N} / b_{1,N} \\
\vdots & \ddots & \vdots \\ 
a_{M,1} / b_{M,1} & \cdots & a_{M,N} / b_{M,N} 
\end{pmatrix}
\end{equation}$

"

# ╔═╡ 3fa2bb2b-d44c-43b7-acb9-9fde251c32e2
md"## 2. Image Foundations"

# ╔═╡ 44c71c4d-5264-4665-b59d-1c6812036ee7
md"Images can be expressed mathematically as functions $f: \Omega \rightarrow \Gamma$ with image domain $\Omega \subseteq \mathbb{R}^D$, where $D \in \mathbb{N}$ is the dimensionality of the image, and the color space $\Gamma$. In most cases $D=2$ but we note that images do not need to be 2D but can also be 3D, 4D, 3D+t, ..."

# ╔═╡ 6ef9fffe-8d1f-4a2e-9da2-bc95ef57033f
example(md"A classical JPEG image from the internet is 2D, a video shown on youtube is 2D+t.")

# ╔═╡ b455c7f2-2f62-468f-90c8-b0648e0673b4
md"
We often write out the image function as 

$f(x,y) \;\text{or}\; f(x,y,t)$
  
or even more general just

$f(\mathbf{r})$ 

where $\mathbf{r}\in \Omega$ is then the (spatial) variable. Usually, $\Omega$ is a subset of the real numbers $\mathbb{R}^D$ in case of a continuous image or a subset of the natural numbers $\mathbb{N}^D$ in case of a discrete image. For instance continuous images are usually defined over $\Omega = [0,1]^D$. If the image has sizes (e.g. $9\,\text{cm} \times 7\,\text{cm}$) one can map to the unit cube by scaling each dimension accordingly. Discrete images are defined over index sets

$I_N =\{1, \dots, N\}$ 

i.e. an $N_x \times N_y$ image could be defined as $f: I_{N_x} \times I_{N_y} \rightarrow  \mathbb{R}$. Discrete images are usually not scaled to $[0,1]^D$ but they are defined on the index coordinates. 
"

# ╔═╡ 77b6681b-7da3-4a1c-ad8c-39a7859a7e08
md"Both continuous and discrete image can have a physical size measured in m (mm, cm, inch, ...). This size can be given by the vector $\mathbf{s}\in \mathbb{R}^D$ such that one can switch between the physical and the normalized domain using the coordinate transform:

$\textbf{r}_\text{physical} = \textbf{s} \odot \textbf{r}_\text{unit cube}$

if the image is defined on the unit cube $[0,1]^D$.

If the image is defined on the index sets we can switch back and forth between image coordinates and physical coordinates using

$\textbf{r}_\text{physical} = \textbf{s} \odot  (\textbf{r}_\text{normalized} - 0.5) \oslash \textbf{N}$

This coordinate transform assumes that we are using a cell-centered grid (see section 2.2). 



"

# ╔═╡ ce2480c4-ef5e-472d-8d93-ad89d41941f3
md"If required one can also extend these definitions with an additional offset, which is helpful when considering a series of images that needs to be stitched together."

# ╔═╡ 7780d458-210d-4bcc-bac6-55becf71b2d3
md"The range is usually chosen to be $\mathbb{R}$, $[0, \infty)$ or $[0, C]$ when considering a continuous range. Most common is to normalize the range to the interval $[0,1]$ (i.e. $C=1$)."

# ╔═╡ ffe390a4-a2c6-4c7e-aa74-442a904ac7ad
md"
##### Pixel
If $f$ is a discrete image it is composed of image *pixels* (*voxels* in 3D). The term pixel is short term for *picture elements* and describes both the coordinates $(\mathbf{r})$, the value $f(\mathbf{r})$ and the pixel size $\Delta$. The later can be the dimensionless pixel size, which is $\Delta = \textbf{1} \oslash \textbf{N}$ for an image on the unit cube and  $\Delta = \textbf{1}$ for indexing coordinates. In case that the image has a physical size one uses the dimensional pixel size $\Delta = \textbf{s} \oslash \textbf{N}$.

Formally one can think of a pixel as a triple $(\mathbf{r},f(\mathbf{r}), \Delta)$. But usually the term is used informally and can mean also a subset of this triple.

##### Intensity

Elements of the color space $\Gamma$ are called *intensities*. They can have some physical meaning including a physical unit but to achieve abstraction, the actual unit is often ignored. If you have camera pictures usually it is the light captured with a sensor that is encoded in the image intensity. 
"

# ╔═╡ 2ead82ba-a1e2-4161-893b-335bd318e4e9
note(md"When *processing* an image one usually considers images having a discrete domain and a continuous range. When *storing* an image both the domain and the range are considered to be discrete.")

# ╔═╡ 8e2729ee-426c-424f-9b4b-feb95f4e4acd
md"
### 2.1 Discrete Images

##### Matrix Representation

Two-dimensional discrete images can be either represented as a function $f(i,j)$ or  as a matrix

$\textbf{f} =\left( f_{i,j}\right)_{i=1,\dots,N_x; j=1,\dots,N_y}= \begin{pmatrix} f(1,1) & \dots & f(1,N_y) \\ \vdots & \vdots & \vdots \\ f(N_x,1) & \dots & f(N_x,N_y)  \end{pmatrix}$

Obviously the matrix entries $f_{i,j}$ correspond to the function values $f(i,j)$.
"

# ╔═╡ 8f188909-48ff-4595-804b-ff13ce456f66
note(md"In image processing one often switches back and forth between the function and the matrix representation. The function representation is more useful if one needs to evaluate an image at off-pixel positions such as in interpolation tasks. The matrix representation is very useful when investigating neighbors of pixels.")

# ╔═╡ cefac419-672c-46f1-aa28-30de645c7863
md"
##### Array Representation
The third representation that we can use is a (multidimensional) array. An array is a programming data structure that can hold a certain number of elements and is usually layed out contiguous in the main memory leading to ${\cal O}(1)$ access times to individual array elements (read/write). 

Multidimensional arrays are stored in linear main memory (or files) by simply traversing the array where the first index is usually the fastest and the last index is usually the slowest. We also name this *flattening* of a multidimensional array into a 1D array. Mathematically one can describe this for an $N_1 \times \dots \times N_d$ array $\mathbf{f}$ like this:

$f_{i_1+N_1(i_2+ N_2 (i_3 +\,\dots\, N_{d-1}i_d)} = f_{i_1, i_2, \dots, i_d}$

For instance for $d=2$ we have

$f_{i_1+N_1i_2} = f_{i_1, i_2}$

This conversion between 1D and multidimensional arrays is also often done implicitly which brings us to the *indexing strategies*. We name the indexing on the right a *multidimensional* or *Cartesian indexing*. The indexing on the left is named *linear indexing*. 

Which one to use depends on the application. If the order of the elements is irrelevant (under a sum) one can use a linear index and prevent some overhead associated with Cartesian indexing. In case of operations where neighborhood relations are important (e.g. a convolution) a Cartesian index is much more efficient. 


"

# ╔═╡ 3e60ad24-2f4a-4df9-a932-077210f88687
md"Let us shortly look into what Julia does here:"

# ╔═╡ 57ee52c9-698b-4588-bf15-f6e46fdfc3a4
B = kron(1:3,(1:2:8)')

# ╔═╡ d70617bb-dcbd-4fa0-82a5-4a68e9ef4496
with_terminal() do
	println("Cartesian indexing")
	for i2 = 1:size(B,2)
		for i1 = 1:size(B,1)
		   println("$i1 $i2 $(B[i1,i2])")
		end
	end
	
	println("Linear indexing")
	for i = 1:length(B) # = size(B,1)*size(B,2)
		println("$i $(B[i])")
	end
end

# ╔═╡ 27fb0a22-1cf2-468e-8ab9-d96042f49fd6
md"
### 2.2 Coordinate System

The parameters $N_x$ and $N_y$ define the image resolution. Its fraction $N_x / N_y$ defines the [aspect ratio](https://en.wikipedia.org/wiki/Aspect_ratio_(image)) of an image. If $N_y>N_x$ then the image is in *landscape* format, if $N_y>N_x$ it is in *portrait* format.
"

# ╔═╡ b7859be8-8d7d-4998-b35f-0d246ba2f29b
md"The coordinate system that we will use most of the time looks like this:"

# ╔═╡ cc146290-8913-4370-b776-4df8ce3cd483
LocalResource("img/CoordinateSystem.jpg",:width=> 600)

# ╔═╡ 9e57e50a-76dd-4083-b4c5-771c584c180a
begin
  fabio = testimage("fabio", nowarn=true)
  heatmap(imresize(fabio,32,32), legend=true, xlabel="y/m", ylabel="x/m", size=(350,350))
end

# ╔═╡ 4513a7b7-c484-4575-9842-316ade398d72
md"**Observations:**
* upper left pixel is the origin (1,1)
* the $x$ axis is the vertical axis and is directed downwards
* the $y$ axis os the horizontal axis and is directed to the right
* the coordinate system is right-handed but just 90 degrees rotated to what you might have expected from a typical $xy$ graph
"

# ╔═╡ 55a34ac7-61b3-4db9-a79c-057c7c0618fb
note(md"We use a one-based integer based indexing with $(1,1)$ being the upper left and $(N_x,N_y)$ being the lower right pixel. This is useful since many programming languages use a 1-based indexing. Another convention is to use $(0,0)$ and $(N_x-1,N_y-1)$. 
")

# ╔═╡ 335a9243-aae3-4fb9-b48a-1052ae2922ea
md"**Image center**

The image center is located at $\textbf{r}_\text{center} = (\frac{N_x+1}{2},\frac{N_y+1}{2})$. This just corresponds to a pixel location in case that both $N_x$ and $N_y$ are odd. One alternative is to define the image center as

$\textbf{r}_\text{center} = \left(\left\lfloor\frac{N_x+1}{2}\right\rfloor,\left\lfloor\frac{N_y+1}
{2}\right\rfloor\right)$

which ensures that always an image index is selected.
"

# ╔═╡ 83ba359d-0c4c-4606-85da-1e0b014e3fee
md"### 2.3 Visualization

We have already displayed an image using colors on the screen what makes somewhat sense since this is the representation that we associate with an image. But there are more ways. Let us first load a real valued image:
"

# ╔═╡ 51f8d471-6150-49dc-8fb3-a45661fb5c90
fabioReal = Float64.(Gray.(testimage("fabio", nowarn=true)));

# ╔═╡ e9d4991b-935f-44b5-81a7-8e7605fb60a2
md"Now we can visualize this image in the following ways:

##### Matrix View

First of all we can look at the image by showing the underlying values in their digit representation:
"

# ╔═╡ 99c31bdf-826a-4839-946c-7fa77f0c7cba
fabioReal

# ╔═╡ 590c1b11-be7d-4903-a541-96bbd168507f
md"This is helpful when you need the precise quantitative values and want to compare. The human perception system is, however, not so good in interpreting this data efficiently."

# ╔═╡ 48e01167-bb5a-4f9b-97a8-fc639b49e877
md"##### Image View

Then of course we can show it as an image. The following shows two ways how you can do this with Julia's plotting package Plots.jl:"

# ╔═╡ 3a098a5e-7e73-4c5d-b82a-1187874d9d2b
heatmap(reverse(fabioReal,dims=1),c=:grays)

# ╔═╡ d3acbe25-a8e1-4845-9174-45d303bba5b7
heatmap(Gray.(fabioReal))

# ╔═╡ 8f2c2190-bfcc-4444-b7fe-cc992e7bf448
md"When showing an image in a colorful representation it is important to take into account that there often is a mapping between the real values image and the color being shown. This *color mapping* will be discussed later in this course but you should be aware of it whenever you display images.

In the above code we once made the color mapping implicitly and once did it explicitly."

# ╔═╡ d8c1b67b-c328-4441-8650-6cb59d240068
md"##### Surface View

The next possibility is to represent the image value $f(x,y) = z$ as the $z$ value in a 3D plot, what we call a *surface plot*. This surface plot can also be colorized:
"

# ╔═╡ c59c13af-3500-4914-a8eb-1f738bcc1c5e
plot(fabioReal,st=:surface, cam=(85,85))

# ╔═╡ 9a4e00ef-f6fb-4800-bc6c-f532fa4c1e89
md"""##### Profile View

Finally it is quite common to use 1D profiles of an image to showcase the progression of the underlying function along a certain direction. Often this is combined with the image view:

x = $(@bind px Slider(1:256; default=53, show_value=true)) \
y = $(@bind py Slider(1:256; default=23, show_value=true)) 
"""

# ╔═╡ 5a252610-abad-4cda-ac17-c6400c1eb59a
begin
	p1a = heatmap(Gray.(fabioReal))
	
	plot!(p1a,[(1,px),(256,px)],lw=2,c="blue",legend=nothing)
	plot!(p1a,[(py,1),(py,256)],lw=2,c="orange",legend=nothing)
	
	p2a = plot(vec(fabioReal[:,py]),lw=2,c="orange",legend=nothing)
	p3a = plot(vec(fabioReal[px,:]),lw=2,c="blue",legend=nothing)
	
	plot(p1a,p2a,p3a)
end

# ╔═╡ 7b6bab2d-b313-46ca-a480-99bead161f07
md"### 2.4 Discretization 

We next shortly review the discretization of a continuous image. We illustrate this using a 1D signal but the generalization to an image is analogous.

The following image shows how to convert an analog into a digital signal:
"

# ╔═╡ e865b5b3-22e5-4029-9afb-cca2159dff66
function quantize(I, vmin, vmax, L)
	if I < vmin
		return vmin	
	elseif I > vmax
		return vmax	
	else
		rData = vmax - vmin
		rQuant = L-1
		return round((I-vmin)/rData*rQuant)*rData/rQuant+vmin
	end
end;

# ╔═╡ e263c8ca-d71c-4c43-90fd-8e9b5c4dce35
begin
	t = range(0,2π,length=200)
	ts = t[1:10:end]
	
	p1 = plot(t,sin.(t),lw=2,label="continuous")
	plot!(ts,sin.(ts),st=:scatter,label="sampling")
	
	p2 = plot(ts,sin.(ts),lw=2,st=:steppost,label="sampled")
	

	p3 = plot(t,quantize.(sin.(t),-1.0,1.0,19),lw=2,st=:steppost,label="quantized")
	
	p4 = plot(ts,quantize.(sin.(ts),-1.0,1.0,19),lw=2,st=:steppost,label="digital")
	
	
	
	plot(p1,p2,p3,p4)
end

# ╔═╡ 2bda92e2-2b34-4afa-9303-d07520c7022a
md"The discretization of the domain is called *sampling* whereas the discretization of the range is called *quantization*."

# ╔═╡ 0398d0c0-05e4-4834-bed1-405d97263876
md"
#### 2.4.1 Sampling

Discretizing the domain of a function is called sampling. The following image shows on the left a continuous image $f(x,y)$ that is sampled at discrete positions

$\{(x_1,y_1), \dots (x_{N_x},y_{N_y})\}$

i.e. the discrete image can be obtained by

$f_\text{discrete}(i,j) = f(x_i, y_j) \quad \text{for}\quad i\in I_{N_x}, j\in I_{N_y}$
"

# ╔═╡ 95378129-1db8-4e48-b2a5-233832f56808
PlutoUI.LocalResource("img/sampling.png",  :width =>500)

# ╔═╡ 4808e961-2a1e-4ae5-8eca-b6b26a2f67a0
md"Quite often, the sampling process has an *integrating* nature and thus, the sampling process is rather described by:"

# ╔═╡ 41004242-0ba9-41d0-b079-f6ccb19bd724
md"
$f_\text{discrete}(i,j) = \int_{x_i - \frac{\Delta_x}{2}}^{x_i + \frac{\Delta_x}{2}} \int_{y_i - \frac{\Delta_y}{2}}^{y_i + \frac{\Delta_y}{2}} f(x,y) \, \text{d}x \, \text{d}y$
"

# ╔═╡ bb6bf28d-9a6b-40ca-b28c-99a4e92f3252
md"where $\Delta_x$ and $\Delta_y$ are the pixel sizes in $x$ and $y$ direction. Which form is used depends on the sensor being used. An integrating sensor is much more common since it maximizes the signal-to-noise ratio."

# ╔═╡ 305a48d4-86d1-4309-bd4b-8f462663bd6d
note(md"Sampling needs to be done properly since otherwise one gets *artifacts* when *reconstructing* $f(x,y)$ from $f_\text{discrete}(i,j)$. We cover this topic later in this lecture and here for now just show you an image what happens if this is not done properly.")

# ╔═╡ 5ec9da2f-ed87-4927-8af1-44abfbf496a8
md"The following picture shows an [aliasing](https://en.wikipedia.org/wiki/Aliasing) artifact named the [moire effect](https://en.wikipedia.org/wiki/Moir%C3%A9_pattern)."

# ╔═╡ 80fa6b7b-dc48-440c-82da-97ea5e85f656
PlutoUI.LocalResource("img/Moire_pattern_of_bricks_small.jpg",  :width =>300)

# ╔═╡ 66ad7fc5-9a59-47e0-9744-648fac9b6749
md"
#### 2.4.2 Quantization

Quantization means that a certain number of bits is chosen to store a real-valued variable. In practice there are two different forms.

##### Floating Point Values

When considering floating point values the quantization is done implicitly by the computer and one hardly needs to think about it. Floating point values allow for covering a huge dynamic range by storing mantissa and exponent individually. When choosing both large enough one can usually ignore rounding errors and can treat floating point numbers as real numbers. CPUs have special units to perform floating point calculations very efficiently.

➔ Floating point values such as `Float64` or `Float32` are usually used when *processing* images. 

The downside of floating point values is that they require more bits than integer values. Thus, they are usually not used for storing images.

##### Integer Values

Integer values cover a range of $2^k$ where $k$ is the number of bits. Since computers use byte addresses, $k$ is usually a multiple of 8. In practice 8bit (one byte), 16bit (two bytes) and 32bit (four bytes) integers are used.
  

"

# ╔═╡ e1ac8a81-585b-4595-94ff-28496c8d9c3f
note(md"At this point we primary consider *unsigned* integers that cover the range $0, \dots, 2^k-1$. When doing calculations one would rather use *signed integers* that cover a range $-2^{k-1}, \dots, 2^{k-1}-1$. The reason is that subtractions can easily lead to surprising overflows when using unsigned integers. However, nowadays floating point units are fast enough such that usually integer arithmetic is not used at all.")

# ╔═╡ 3fb28a94-8a34-45f7-bb72-6c07aa9841a3
md"
##### Scaling/Offset

At some point one often wants to convert an integer value back to a floating point value representing the original range. Therefore, one often represents an image as:

$f(x,y) = \alpha f_\text{normalized}(x,y) + \beta$

where $f_\text{normalized}\in [0,1]$ are the normalized image values, 

$\beta= \text{min}_{x,y}(f(x,y))$

is the offset, and

$\alpha=\text{max}_{x,y}(f(x,y))  - \text{min}_{x,y}(f(x,y))$

is the scaling parameter.

The scaling/offset parameters are global values that are stored only once for the entire image.

The normalized image can be calculated by

$f_\text{normalized}(x,y) = \frac{ f(x,y) - \beta}{\alpha}.$

"

# ╔═╡ 2efeb29a-71f3-4791-ae0b-b1bbe1f627dc
md"##### Performing Quantization

The quantization can be done in the following steps:
1. Calculate $\alpha$ and $\beta$.
2. Calculate $f_\text{normalized}(x,y)$
3. Calculate $f_\text{integer}(x,y) = \text{round}((2^k-1)f_\text{normalized}(x,y))$

"

# ╔═╡ bf885022-de9d-4bca-8288-b22c07007a85
md"##### Example

Let us have look at what quantization implies in practice. Next you can see a quantization of an image with different numbers of bits:
"

# ╔═╡ e14c4a92-62de-4556-9525-e05ff4dd03e9
begin
	pq = Any[]
	fabioGrayFull = Gray.(testimage("fabio", nowarn=true))
	
	for k in [8, 6, 4, 3, 2, 1]
		fabioQuant = quantize.(Float64.(fabioGrayFull), 
			                  minimum(fabioGrayFull), maximum(fabioGrayFull), 2^k)
		push!(pq, heatmap(Gray.( fabioQuant ), size=(800,550), 
				  title="""k=$k bit$(k==1 ? "s" : "")"""))
	end
	plot(pq...)
end

# ╔═╡ a7d9ce0f-9db9-485a-a56c-0e210bcb391c
md"**Observations:**
* One can hardly see a difference between 8 and 6 bits.
* When using 4 and less bits one can clearly see quantization effects, which manifest themselves into larger regions having the same value.
"

# ╔═╡ 7a6f36b4-2d91-43b5-ba85-b1642371cd84
md"### 2.5 Image Characteristics

Images can be characterized using different metric that are discussed next.
"

# ╔═╡ 0427d65a-a4f2-4514-b3e1-01a3f67685e0
md"#### 2.5.1 Spatial Resolution

The resolution determines the number of details that can be distinguished. We differentiate between
* The pixel resolution that is determined by $N_x$ and $N_y$.
* The physical resolution of the underlying function $f(x,y)$ which can be lower (or higher) because of the physics during the acquisition process. 

The following shows two images both having a pixel resolution of $1920 \times 1920$. The left has a full spatial resolution, the right is blurred and in turn the spatial resolution is much lower.

"

# ╔═╡ 019259e2-532d-470e-99ed-242de888a846
begin
	testPhantom = testimage("resolution_test_1920")
	
    pr1 = heatmap(testPhantom,size=(800,400))
	pr2 = heatmap(imfilter(testPhantom, Kernel.gaussian(20)),size=(800,400))
	
	plot(pr1,pr2)
end

# ╔═╡ 143654c3-02cd-41cb-8047-ddebd0c60f55
md"##### Physical Resolution

The (spatial) resolution is a measure defined either as a length or a spatial frequency. One can determine/define the resolution using the distance of two dots/lines that move to each other with a certain gap that has the same width as each dot. If the function value at the gap is less than 50% of the value at the dots, the dots count as resolved. This is illustrated in the next image where the green line shows the original dots with infinite resolution and the blue line shows the function after performing acquisition with a certain resolution. One can see that the spatial resolution is about 1 mm.
"

# ╔═╡ f1294882-cbee-4b9f-88c1-cbb507d6e8f3
LocalResource("img/resolutionConvolutionLinepairs.svg")

# ╔═╡ ef50b36d-b9f2-479b-84dc-4bf3a3904f29
md"For further reading you can have a look at this wikipedia article on [optical resolution](https://en.wikipedia.org/wiki/Optical_resolution), which is more tailored towards the resolution properties of the optical elements before digitization."

# ╔═╡ bc7e7e91-0c60-48d0-832c-91441f095936
md"##### Image Resolution

(see also the [wikipedia article](https://en.wikipedia.org/wiki/Image_resolution))

The image resolution is given by the size of an image pixel. If the $N_x \times N_y$ image is associated with a certain image size (width $w$ and height $h$) the resolution can be also reported as the pixel size

$\Delta_x = \frac{h}{N_x}, \quad \Delta_w = \frac{w}{N_y}$

Quite often the reciprocal is reported as *lines per millimeter*, *line pairs per millimeter* or [pixels per inch](https://en.wikipedia.org/wiki/Pixel_density) (ppi).

The term *resolution* is also often used for the number of pixels in the image, i.e. $N_x \times N_y$. This is of course just a simplification and requires the image size to translate this to a (dimensional) resolution.

"

# ╔═╡ 2bde0c1e-776e-4c31-96ae-8cb7011c6cf0
example(md"
→ A typical movie in what is called *Full HD* has $1920\times 1080$ pixels. Its image resolution cannot be stated because it depends on the output device.\
→ An iphone 11 has an LCD screen with  $1792 \times 828$ pixels, an image resolution of 326 ppi (12.834646 pixel/mm, 77.9141 μm pixel size), a screen size of (139.622 mm
$\times$ 64.5129 mm) and an associated diagonal of 153.80 mm.
")

# ╔═╡ a8442bd1-478d-4a92-a935-b7bae41a2417
md"The following images show what happens if we decrease the image size:"

# ╔═╡ 035bed81-2cb3-45d1-aa15-1f0038fe22c9
begin
	p = Any[]
	I2 = testimage("resolution_test_1920")
	for k in [1024, 512, 128, 64]
		push!(p, 
			heatmap(imresize(I2,(k,k)), size=(800,830), legend=true, title="Nₓ = $k")
			)
	end
	plot(p...)
end

# ╔═╡ 7217ed4a-8526-44b2-b7ee-cad616e78a34
md"One can see two effects:
* Fine details cannot be shown anymore if the number of used pixels is too low.
* Without additional band limitation we obtain aliasing errors (discussed in upcoming lectures)."

# ╔═╡ c15669d7-6f38-4d81-a0f8-b02b91bd024d
md"#### 2.5.2 Contrast

The [contrast](https://en.wikipedia.org/wiki/Contrast_(vision)) of an image can be defined in different ways. It is quite common to use the *michelson contrast* that is defined as

$C(f) = \frac{\text{max}(f)-\text{min}(f)}{\text{max}(f)+\text{min}(f)}$

It basically measures how large the maximum variation in the image intensity is and relates that to twice of the mean value. Let us define it and have a look at the contrast of some images:
"

# ╔═╡ 642adb73-f7cd-4f93-9fcc-78e389be67e1
contrast(f) = (maximum(f)-minimum(f)) / (maximum(f)+minimum(f));

# ╔═╡ fb7395eb-8a06-48dc-8b37-af14deab04b2
let
	pq = Any[]
	lenaGrayFull = Gray.(testimage("fabio", nowarn=true))
	
	for k in 1:6
		lenaContrast = lenaGrayFull./k .+ (0.5 - 1/(2*k))  
		C = contrast(lenaContrast)
		s = @sprintf "C=%.2f" C
		push!(pq, heatmap(Gray.( lenaContrast ), size=(800,550), 
				  title=s))
	end
	plot(pq...)
end

# ╔═╡ bd1a4424-7abc-460a-9e36-e57592e76fbf
md"One can clearly see how it gets more difficult to distinguish parts of the image when the image contrast gets lower."

# ╔═╡ 71809ab0-c38d-440c-a1f9-0bc0c39781f7
md"#### 2.5.3 Noise

Often the image is contaminated by noise. Mathematically this can be modelled by:

$f(\mathbf{r}) = f_\text{true}(\mathbf{r}) + \varepsilon(\mathbf{r})$

where $f_\text{true}(\mathbf{r})$ is the true noise free image and  $\varepsilon(\mathbf{r})$ is a noise image that (usually) contains in each pixel an uncorrelated random number with a certain mean and standard deviation.

"

# ╔═╡ c6b1f451-0e2c-47e7-af93-c7b2fd304cb1
md"The following pictures show the Fabio image with different amounts of noise being added. The standard deviation is given in percentage of the maximum value in the true image."

# ╔═╡ 172e54c9-fed4-452f-a250-7d3fa1804337
let
	pq = Any[]
	lenaGrayFull = Float64.(Gray.(testimage("fabio", nowarn=true)))

	for noise in range(0,0.5, length=6)

		lenaNoise = lenaGrayFull + randn(size(lenaGrayFull))*noise*maximum(lenaGrayFull)

		s = "$(noise*100) %"
		push!(pq, heatmap(Gray.( lenaNoise ), size=(800,550), 
				  title=s))
	end
	plot(pq...)
end

# ╔═╡ 452e4560-5acf-4696-9aa1-34b423370dd7
md"One can see how the noise degrades the overall image quality and makes it difficult to see the underlying image.  "

# ╔═╡ 6564ea12-baaf-46e5-9861-5690a5ef2e09
note(md"The image characteristics resolution, contrast and noise are mostly independent of each other. But it is still much more challenging to inspect high resolution features in a noisy image. The contrast is usually increased when adding noise. But this increase in contrast does not match our visual impression and is thus somewhat artificial.")

# ╔═╡ 913d2460-c36e-4066-9ac4-d883e468499e
md"#### 2.5.4 Intensity Resolution"

# ╔═╡ eb9ad94b-bdc1-49d3-91e8-d8dc1670ca49
md"Similar to the spatial resolution we can also define a resolution for the image intensity. This is named intensity resolution and specified by the bin size that is captured when changing the least significant bit. If the range is normalized the intensity resolution can also be given as the number of bits used for discrimination."

# ╔═╡ 6100b888-2503-4e94-8241-52c1cbf15d18
note(md"Similar to that spatial resolution, an can image not always resolve the entire intensity resolution. There are two possible causes:\
→ When storing an image with a higher bit depth one cannot resolve more intensities.\
→ Most images contain a certain amount of noise. If this noise is larger than the bit resolution, the noise limits the intensity resolution. Simple example is if you take a picture with your still camera in a dark room.")

# ╔═╡ ab5b00ca-c0ad-44e7-9f96-0ba1372a4edb
md"### 2.6 Memory Footprint
In uncompressed form an image requires to store

$b = N_x N_y k$

bits or $b/8$ bytes. An image data structure also needs to store the size $(N_x,N_y)$ which can be stored in a *header*. Such a header is also used in image file formats. Consequently, the actual file size is usually slightly larger than in the above formula. 

Here is a graph showing the number of bytes required to store an image depending on the image size $N = N_x = N_y$:

"

# ╔═╡ d16e980f-b0a0-4e76-8c4c-521a37ea5601
begin
	N = collect(1:100:10000)
	nBits = [8, 16, 32]
	pmem = plot(N./ 1000, 1 ./ 8 .* (N .^ 2) / 1e6, lw=2, xlabel="N / 1000", ylabel="Megabytes",  label="1 bit", legend=:topleft)
	for b in nBits
	  plot!(pmem, N ./ 1000, b ./ 8 .* (N .^ 2) / 1e6, lw=2, label="$b bits")
	end
	pmem
end

# ╔═╡ 03748a78-09fe-44b6-8fac-736eada78d15
md"Note that 1 bit is often used to store text images (so-called binary images), 8 bits is a typical value for regular grayscale images and 4 bytes is typical for colored images (one byte for red, green, blue and alpha)."

# ╔═╡ 3a9e4b32-34cc-4c83-837f-dda432ea764d
md"## 3. Image Interpolation

A fundamental operation that is required in image processing is (image) interpolation. As an example we consider the task of rotating an image and evaluating it on the original grid: 

"

# ╔═╡ 5022552a-c701-49b4-94de-b94ef4bf4864
LocalResource("img/offgrid.svg",:width=>500)

# ╔═╡ c80d38c0-6752-4017-a3c8-c54a2f6c1fad
md"
In such a situation we wish that the image would be continuous and could be evaluated at offgrid positions. And this is exactly what interpolation does. 

Interpolation means that we take a discrete image $f_\text{discrete}(i,j)$ of size $N_x \times N_y$ that is available at positions $i \in I_{N_x}, j \in I_{N_y},$ and aim to evaluate this image at non-integer coordinates.

The most common method for interpolation is [spline interpolation](https://en.wikipedia.org/wiki/Spline_interpolation). Spline interpolation uses low-degree polynomials through given points, which can be evaluated at offgrid positions afterwards.

The interpolating function $f_\textrm{interp}$ is then a function $f_\textrm{interp}(i,j) : [1,N_x] \times [1,N_y] \rightarrow \Gamma$.
"

# ╔═╡ a9cb5cf9-8a48-4451-922c-b9d9cc266e1f
note(md"We name it *interpolation* if we get the exact function values back when evaluating $f_\textrm{interp}$ at the indices $(i,j)$, i.e. $f_\textrm{interp}(i,j)=f_\text{discrete}(i,j)$. Otherwise we call it *approximation*. Interpolation is usually done when the given data can be fully trusted. Approximation is done when the data has uncertainties since interpolation would then try to follow the progression of noise, which is undesired.")

# ╔═╡ 7798d01e-373a-4858-b804-228159242101
md"The difference between regular polynomial interpolation and spline interpolation is that the former uses a global polynomial with a high degree while the latter uses multiple low-degree polynomials in short intervals and chooses the polynomial pieces such that they fit smoothly together. Spline interpolation is much more common since it avoids large oscillations, which connot be avoided in regular polynomial interpolation.

The next image shows some 1D and 2D spline interpolations for polynomial degrees 0, 1 and 3:"

# ╔═╡ 90a5ab07-1d5d-44e3-91d3-16afadf64ec6
LocalResource("img/Comparison_of_1D_and_2D_interpolation.svg")

# ╔═╡ 3221d531-1fab-418b-8ad9-bc543b1bdfb7
md"
##### Nearest-Neighbor

This is the most simple interpolation scheme, where the nearest point in space is taken as the function value. This is equivalent to setting up rectangular function around each pixel which has exactly the width of the pixel.

##### Linear

In linear interpolation one takes the neighborhood into account and takes a linear function that goes through neighboring pixels. In 1D this is two points while in 2D the interpolation takes $2\times 2 = 4$ points.

The interpolation function for the area between the pixels $(i,j)$ and $(i+1,j+1)$ is expressed as

$f_\textrm{linear}^{i,j}(x,y) = a^{i,j}x + b^{i,j}y + c^{i,j}xy + d^{i,j}$

where the coefficients $a^{i,j}$ to $d^{i,j}$ depend on the values $f(i,j)$, $f(i+1,j)$, $f(i,j+1)$, $f(i+1,j+1)$. Here, we assume that the function $f_\textrm{linear}^{i,j}(x,y)$ is shifted such that 

$f_\textrm{linear}^{i,j}(0,0) = f_\textrm{discrete}(i,j).$


##### Cubic

We skip quadratic interpolation since one usually directly goes to cubic interpolation when aiming for a more smooth transition between the points.

The issue with linear interpolation is that it is not differentiable at the grid points, which leads to visible interpolation artifacts. Higher degree polynomials do not suffer from this problem.

In cubic interpolation one needs to take even more neighbors, i.e. in 2D $4\times 4 = 16$ points are required. The interpolation function then can be expressed as

$f_\textrm{linear}^{i,j}(x,y) = \sum_{l=0}^{3} \sum_{k=0}^{3} a^{i,j}_{l,k} x^l y^k$

Again, the coefficients depend on the local neighborhood. In cubic spline interpolation the local $4 \times 4$ patches are overlapping and they are chosen in such a way that the transition is smooth (i.e. twice differentiable).

"

# ╔═╡ 91919d10-1302-446c-9f64-822b39fdff2a
md"##### Examples

Here are some examples of using different interpolation techniques, which are available in the *Interpolations.jl* package.
"

# ╔═╡ 76cbafb6-24df-4937-967f-40d1967fe760
begin
	lenaGray = Float64.(Gray.(testimage("fabio", nowarn=true)))[100:2:160,110:2:190]
	NI = size(lenaGray)
	M = 300
	
	lenaNN = interpolate(lenaGray, BSpline(Constant()))
	lenaLinear = interpolate(lenaGray, BSpline(Linear()))
	lenaCubic = interpolate(lenaGray, BSpline(Quadratic(Reflect(OnCell()))))
	
	pNN = heatmap(Gray[lenaNN[x,y] for x=range(1,NI[1],length=M), y=range(1,NI[2],length=M)], title="Nearest Neighbor", size=(600,635))
	
	pLinear = heatmap(Gray[lenaLinear[x,y] for x=range(1,NI[1],length=M), y=range(1,NI[2],length=M)], title="Linear",size=(600,635))
	
	pCubic = heatmap(Gray[lenaCubic[x,y] for x=range(1,NI[1],length=M), y=range(1,NI[2],length=M)], title="Cubic",size=(600,635))
	
	plot(pNN, pLinear, pCubic)
end

# ╔═╡ ae1e465f-ad09-477f-add1-6abfa0ad97c8
md"##### Boundary Conditions

For polynomial degrees larger than one, the boundary pixels have to be handled differently. There are different so-called boundary conditions that can be applied. Usually one *extrapolates* the missing pixels and then applies the regular interpolation scheme.

Here are some common extrapolation strategies:
* Flat: Take a constant value from the boundary and keep it constant when going outside.
* Linear: Calculate the derivative at the boundaries and let the value increase linearly.
* Reflect: Reflect the entire image and put the reflected images behind all boundaries. Behind the corners one needs to reflect twice.
* Periodic: Assume that the image is periodic and simply wrap around the indices.
"

# ╔═╡ 458ab998-d0f2-4be3-920b-47ff039af954
begin
	lenaFlat = extrapolate(interpolate(lenaGray, BSpline(Linear())), Flat())
	lenaLin = extrapolate(interpolate(lenaGray, BSpline(Linear())), Linear())
	lenaReflect = extrapolate(interpolate(lenaGray, BSpline(Linear())), Reflect())
	lenaPeriodic = extrapolate(interpolate(lenaGray, BSpline(Linear())), Periodic())
		
	pFlat = heatmap(Gray[lenaFlat[x,y] for x=range(-NI[1]/2,NI[1]*3/2,length=M), y=range(-NI[2]/2,NI[2]*3/2,length=M)], title="Flat", size=(600,635))
		
	pLin = heatmap(Gray[lenaLin[x,y] for x=range(-NI[1]/2,NI[1]*3/2,length=M), y=range(-NI[2]/2,NI[2]*3/2,length=M)], title="Linear", size=(600,635))
	
	pReflect = heatmap(Gray[lenaReflect[x,y] for x=range(-NI[1]/2,NI[1]*3/2,length=M), y=range(-NI[2]/2,NI[2]*3/2,length=M)], title="Reflect", size=(600,635))
	
	pPeriodic = heatmap(Gray[lenaPeriodic[x,y] for x=range(-NI[1]/2,NI[1]*3/2,length=M), y=range(-NI[2]/2,NI[2]*3/2,length=M)], title="Periodic", size=(600,635))
	
	
	plot(pFlat, pLin, pReflect, pPeriodic)
	
end

# ╔═╡ bf6c6e3d-568d-43fa-940c-4d12dc982323
md"## 4. Image Transformations

In image processing we usually take an input image $f(x,y)$ and process it resulting to an image $g(x,y)$. This is called *transformation*, *operator* (mathematics), or *system* (signal processing).

Mathematically the transformation can be defined as a function operating on images: 

$T: (\Omega_1 \rightarrow \Gamma_1) \rightarrow (\Omega_2 \rightarrow \Gamma_2)$
"

# ╔═╡ a58195d5-c969-465c-86e6-eaf26b6d6d57
example(md"The operator

$T_\textrm{invert}(f(x,y)) = \textrm{max}(f(x,y)) - f(x,y)$	

inverts the intensity range.
")

# ╔═╡ 3b1447c5-04a5-4d56-a87a-6553b65de216
begin
	invertIntensity(f) = maximum(f) .- f
	
	lenaGray_ = Float64.(Gray.(testimage("fabio", nowarn=true)))
	plot( heatmap(Gray.(lenaGray_), size=(800,380)),
		  heatmap(Gray.(invertIntensity(lenaGray_)),size=(800,380))
		)
end

# ╔═╡ 3d6262b8-8aec-4f26-a459-2f8d01d6be6b
md"### 4.1 Linear Transformations

A transformation $T$ is linear if


$T(\alpha f(x,y) + g(x,y) ) = \alpha T(f(x,y)) + T(g(x,y))$ 

In the discrete case, linear transformations can be expressed as

$T(f(x,y)) = g(u, v) = \sum_{x=1}^{N_x} \sum_{y=1}^{N_y}  f(x,y) s(x,y,u,v) \quad u \in I_{N_x}, v \in I_{N_y}$

where $s(x,y,u,v)$ is the so-called  *(forward) transformation kernel*.

##### Inverse Transformation

In many cases there exists an inverse transformation $T^{-1}$ with  $T^{-1}(T(f(x,y))) = f(x,y)$ that can be expressed as

$T^{-1}(g(u,v)) = f(x,y) = \sum_{u=1}^{N_x} \sum_{v=1}^{N_y}   g(u,v) r(x,y,u,v) \quad u \in I_{N_x}, v \in I_{N_y}$

The function $r(x,y,u,v)$ is called the *inverse transformation kernel*.
"

# ╔═╡ 2b38a601-ecca-414a-b873-5a81081c37a2
md"##### Separable Kernel

An integral kernel is said to be separable if it can be expressed as

$s(x,y,u,v) = s_x(x,u) s_y(y,v)$

If $s_x = s_y$ the kernel is said to be symmetric. For separable kernels the transformation can be rearranged as

$T(f(x,y))(u, v) = \sum_{y=1}^{N_y} s_y(y,v) \left(\sum_{x=1}^{N_x}  f(x,y) s_x(x,u)  \right) \quad u \in I_{N_x}, v \in I_{N_y}$


Thus, the 2D transformation can be carried out by first doing $N_y$ 1D transformations in $x$ direction and then $N_x$ 1D transformations in $y$ direction. This requires ${\cal O}(N_x^2 N_y + N_y^2 N_x)$ operations instead of ${\cal O}(N_x^2 N_y^2)$ which are required for a non-separable kernel. This lowers the time complexity considerably.

"

# ╔═╡ 31eb4748-1ff5-4265-a2cd-17d83f2ad4b4
md"### 4.2 Shift Invariance

A transformation is shift-invariant if


$T(f(x- x_0, y-y_0))(u, v) = T(f(x,y))(u- x_0, v-y_0)$

Shift invariance plays an important role in many image processing algorithms. One important characteristic of linear shift invariant operators is that one can express them as a convolution

$T(f(x,y)) = g(u, v) = \sum_{y=1}^{N_y} \sum_{x=1}^{N_x}  f(u-x,v-y) h(x,y)  = (f\ast h) (u, v)$

Here $h(x,y)$ is the so-called impulse response or point-spread function (PSF), convolution kernel or filter kernel. 

We will discuss convolution in more depth in one of the following lectures.

"

# ╔═╡ c50fd20e-0a00-42f6-aeaf-c9909f0034fb
note(md"In practice the kernel $h$ can also have a different size then the input image $f$. In these cases $h$ is of size $M_x \times M_y$ and the above definitions have to be adapted accordingly.")

# ╔═╡ eda71e41-9d14-4b0d-a49c-df7bb943a528
md"### 4.3 Matrix Vector Notation

We have expressed linear transformations using summations. Alternatively one can 
exploit/reuse the linear algebra formalisms. To this end, we first need to treat images as vectors. This can be done by using the linear indexing discussed before, i.e. we consider $\textbf{f} \in \mathbb{R}^{N}$ to be our image.


Then a linear transformation can be expressed as the matrix vector operation

$\textbf{T} \textbf{f}$

where $\textbf{T} \in \mathbb{R}^{M\times N}$ is the system matrix. 

This means that most of the time in image processing we take an image, multiply a matrix from the left, and then often proceed with another operation. A chain of $D$ transformations can be compactly written as

$\textbf{T}_D \cdots \textbf{T}_1  \textbf{f}.$
"

# ╔═╡ 5b1d6d05-37a8-4fec-ad5d-21304ae54d32
md"### 4.4  Fast Transformations

A regular transformation of an image with $N=N_x N_y$ pixels requires ${\cal O}(N^2)$ operations if we assume $M=N$. In many cases this is a high computational effort. Fortunately for many transformations, such as the Fourier transform or the Wavelet transform, there are faster algorithms that can carry out a transformation in only ${\cal O}(N \log N)$ operations. Pointwise transformations can be even carried out in only ${\cal O}(N)$ operations.
"

# ╔═╡ 6278f523-b1c6-4d0b-a0cc-3abba3bbcd81
note(md"When designing an image processing pipeline you always should take care of the computational complexity of the pipeline and try avoiding quadratic cost if possible.")

# ╔═╡ 06059812-a00f-4658-993f-4b86ae3a8166
md"## 5. Geometric Transformations

Some very simple but useful transformations are geometric transformations, where the intensity itself is kept as it is but instead the spatial variable is transformed. In the most general form we can express this as

$T_\text{geom}(f(\textbf{r})) = f(\varphi(\textbf{r}) ) = g(\textbf{r})$

where $\varphi : \Omega \rightarrow \Omega$ is the coordinate transform. Often this transform has additional restrictions, i.e. $\varphi$ is usually considered to be bijective.
"

# ╔═╡ 266134a9-6503-41a7-b028-d8481412fb33
note(md"Since $\varphi$ changes the position $\textbf{r}$ the image $f$ is usually evaluated at off-grid positions. Thus, performing a geometric transformation usually involves interpolation.")

# ╔═╡ f2627bb4-376e-412e-89ce-181669e479a9
md"### 5.1 Affine Linear Transformations

A very important class of geometric transformations are the so-called affine linear transformations. They can be expressed as

$\varphi(\textbf{r}) = \textbf{A} \textbf{r} + \textbf{b}$

where $\textbf{A} \in \mathbb{R}^{2\times 2}$ and $\textbf{b} \in \mathbb{R}^2$. Here are some typical transformations

| Name | $\textbf{A}$ | $\textbf{b}$ | 
| -----| -----         | -----        | 
| Translation | $\begin{pmatrix}1&0\\0&1 \end{pmatrix}$ | $\begin{pmatrix}t_x\\t_y \end{pmatrix}$ |  
| Scaling / Reflection | $\begin{pmatrix}c_x&0\\0&c_y \end{pmatrix}$ | $\begin{pmatrix}0\\0 \end{pmatrix}$ | 
| Rotation (clockwise) | $\begin{pmatrix}\cos \alpha& \sin \alpha\\-\sin \alpha& \cos \alpha \end{pmatrix}$ | $\begin{pmatrix}0\\0 \end{pmatrix}$ | 
| Shearing | $\begin{pmatrix}1&s_v\\0&1 \end{pmatrix}$ or $\begin{pmatrix}1&0\\s_h&1 \end{pmatrix}$| $\begin{pmatrix}0\\0 \end{pmatrix}$ | 

One can combine multiple transformation my multiplying the transformation matrices $\textbf{A}_1 \textbf{A}_2 ... \textbf{A}_d$. The rightmost transformation is applied first to the spatial variable.
"

# ╔═╡ 9453b3c5-2738-43bf-b475-955153154647
note(md"One can embed the $2\times 2$ matrix and the translation into a $3\times 3$ matrix and use so-called [homogeneous coordinates](https://en.wikipedia.org/wiki/Homogeneous_coordinates). This has the advantage that the translation needs not to be handled separately and the transformation becomes linear in the higher dimensional space.")

# ╔═╡ 96ebc13d-478d-4390-ae8c-0fa6414dcec2
md"##### Examples

Here are some examples of standard affine linear transformations using the [ImageTransformations.jl](https://juliaimages.org/stable/pkgs/transformations/) and the [CoordinateTransformations.jl](https://github.com/JuliaGeometry/CoordinateTransformations.jl) packages:
"

# ╔═╡ a0a70b85-2842-437a-b170-5f32ebff0f01
begin
	img = testimage("camera")
	
    tr1 = AffineMap([1.0 0;0 1.0], [200.0,0.0])
	im = warp(img, tr1)
	pGeom1 = heatmap( axes(im)..., collect(im), title="translation")	
	
	tr2 = recenter(RotMatrix(pi/8), Images.center(img))
	pGeom2 = heatmap( collect(warp(img, tr2)), title="rotation")
	
    tr3 = AffineMap([-1.0 0;0 0.3], [0.0,0.0])
	pGeom3 = heatmap( collect(warp(img, tr3)), title="scaling/reflection")
	
    tr4 = AffineMap([1.0 0.0;1.0 1], [0.0,0.0])
	pGeom4 = heatmap( collect(warp(img, tr4)), title="shearing" )
	

	plot(pGeom1,pGeom2,pGeom3,pGeom4, size=(800,835))
end

# ╔═╡ 24ad59d4-0591-4521-b033-a656f3df3989
md"## 6. Wrapup

In this lecture you have learned how images are represented mathematically as functions and what the typical characteristics of image functions are. In addition you have learned how images can be processed using transformations.
"

# ╔═╡ c58592c3-335c-4468-aac0-23ec3d28b455
md"
## Binary Operations

## Regions
";

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CoordinateTransformations = "150eb455-5306-5404-9cee-2592286d6298"
ImageTransformations = "02fcd773-0e25-5acc-982a-7f6622650795"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Interpolations = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
Rotations = "6038ab10-8711-5258-84ad-4b1120ba62dc"
TestImages = "5e47fb64-e119-507b-a336-dd2b206d9990"

[compat]
CoordinateTransformations = "~0.6.3"
ImageTransformations = "~0.10.0"
Images = "~0.26.0"
Interpolations = "~0.15.1"
Plots = "~1.40.8"
PlutoUI = "~0.7.52"
Rotations = "~1.6.0"
TestImages = "~1.8.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "34e01006c3a5f29e20e10aaeae46fd34b1596014"

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
git-tree-sha1 = "6a55b747d1812e699320963ffde36f1ebdda4099"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.0.4"
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
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "3640d077b6dafd64ceb8fd5c1ec76f7ca53bcf76"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.16.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = "CUDSS"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

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
git-tree-sha1 = "b5278586822443594ff615963b0c09755771b3e0"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.26.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

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
git-tree-sha1 = "66c4c81f259586e8f002eacebc177e1fb06363b0"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.11"
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
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "4820348781ae578893311153d69049a93d05f39d"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.0"

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
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "ee28ddcd5517d54e417182fec3886e7412d3926f"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.8"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f31929b9e67066bee48eec8b03c0df47d31a74b3"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.8+0"

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
git-tree-sha1 = "d1d712be3164d61d1fb98e7ce9bcbc6cc06b45ed"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.8"

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
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

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
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

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
git-tree-sha1 = "3447781d4c80dbe6d71d239f7cfb1f8049d4c84f"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.6"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "437abb322a41d527c197fa800455f79d414f0a3c"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.8"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils", "Libdl", "Pkg", "Random"]
git-tree-sha1 = "5bc1cb62e0c5f1005868358db0692c994c3a13c6"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.1"

[[deps.ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "d65554bad8b16d9562050c67e7223abf91eaba2f"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.13+0"

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
git-tree-sha1 = "44664eea5408828c03e5addb84fa4f916132fc26"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.8.1"

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
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

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
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "36bdbc52f13a7d1dcb0f3cd694e01677a515655b"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.0+0"

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
git-tree-sha1 = "9fd170c4bbfd8b935fdc5f8b7aa33532c991a673"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.11+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fbb1f2bef882392312feb1ede3615ddc1e9b99ed"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.49.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "b404131d06f7886402758c9ce2214b636eb4d54a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.0+0"

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
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll"]
git-tree-sha1 = "fa7fd067dca76cadd880f1ca937b4f387975a9f5"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.16.0+0"

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
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "libpng_jll"]
git-tree-sha1 = "f4cb457ffac5f5cf695699f82c537073958a6a6c"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.5.2+0"

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
git-tree-sha1 = "7493f61f55a6cce7325f197443aa80d32554ba10"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+1"

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
git-tree-sha1 = "6e55c6841ce3411ccb3457ee52fc48cb698d6fb0"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.2.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "650a022b2ce86c7dcfbdecf00f78afeeb20e5655"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.2"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "45470145863035bb124ca51b320ed35d071cc6c2"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.8"

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

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll"]
git-tree-sha1 = "e5dd466bf2569fe08c91a2cc29c1003f4797ac3b"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.7.1+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "1a180aeced866700d4bebc3120ea1451201f16bc"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.7.1+1"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "729927532d48cf79f49070341e1d918a65aba6b0"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.7.1+1"

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
git-tree-sha1 = "38f139cc4abf345dd4f22286ec000728d5e8e097"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.10.2"

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
git-tree-sha1 = "e7f5b81c65eb858bed630fe006837b935518aca5"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.70"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

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

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "1165b0443d0eca63ac1e32b8c0eb69ed2f4f8127"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ac88fb95ae6447c8dda6a5503f3bafd496ae8632"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.6+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "326b4fea307b0b39892b3e85fa451692eda8d46c"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.1+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "3796722887072218eabafb494a13c963209754ce"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.4+0"

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

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

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

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "936081b536ae4aa65415d869287d43ef3cb576b2"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.53.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

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

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

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

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

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
# ╟─4ddfffe8-60f4-437f-b3ff-3c10820ac249
# ╟─468ad103-3cea-4860-b6d7-6e267f8ba0d9
# ╟─3fa2bb2b-d44c-43b7-acb9-9fde251c32e2
# ╟─44c71c4d-5264-4665-b59d-1c6812036ee7
# ╟─6ef9fffe-8d1f-4a2e-9da2-bc95ef57033f
# ╟─b455c7f2-2f62-468f-90c8-b0648e0673b4
# ╟─77b6681b-7da3-4a1c-ad8c-39a7859a7e08
# ╟─ce2480c4-ef5e-472d-8d93-ad89d41941f3
# ╟─7780d458-210d-4bcc-bac6-55becf71b2d3
# ╟─ffe390a4-a2c6-4c7e-aa74-442a904ac7ad
# ╟─2ead82ba-a1e2-4161-893b-335bd318e4e9
# ╟─8e2729ee-426c-424f-9b4b-feb95f4e4acd
# ╟─8f188909-48ff-4595-804b-ff13ce456f66
# ╟─cefac419-672c-46f1-aa28-30de645c7863
# ╟─3e60ad24-2f4a-4df9-a932-077210f88687
# ╠═57ee52c9-698b-4588-bf15-f6e46fdfc3a4
# ╠═d70617bb-dcbd-4fa0-82a5-4a68e9ef4496
# ╟─27fb0a22-1cf2-468e-8ab9-d96042f49fd6
# ╟─b7859be8-8d7d-4998-b35f-0d246ba2f29b
# ╟─cc146290-8913-4370-b776-4df8ce3cd483
# ╠═9e57e50a-76dd-4083-b4c5-771c584c180a
# ╟─4513a7b7-c484-4575-9842-316ade398d72
# ╟─55a34ac7-61b3-4db9-a79c-057c7c0618fb
# ╟─335a9243-aae3-4fb9-b48a-1052ae2922ea
# ╟─83ba359d-0c4c-4606-85da-1e0b014e3fee
# ╠═51f8d471-6150-49dc-8fb3-a45661fb5c90
# ╟─e9d4991b-935f-44b5-81a7-8e7605fb60a2
# ╠═99c31bdf-826a-4839-946c-7fa77f0c7cba
# ╟─590c1b11-be7d-4903-a541-96bbd168507f
# ╟─48e01167-bb5a-4f9b-97a8-fc639b49e877
# ╠═3a098a5e-7e73-4c5d-b82a-1187874d9d2b
# ╠═d3acbe25-a8e1-4845-9174-45d303bba5b7
# ╟─8f2c2190-bfcc-4444-b7fe-cc992e7bf448
# ╟─d8c1b67b-c328-4441-8650-6cb59d240068
# ╠═c59c13af-3500-4914-a8eb-1f738bcc1c5e
# ╟─9a4e00ef-f6fb-4800-bc6c-f532fa4c1e89
# ╟─5a252610-abad-4cda-ac17-c6400c1eb59a
# ╟─7b6bab2d-b313-46ca-a480-99bead161f07
# ╟─e865b5b3-22e5-4029-9afb-cca2159dff66
# ╟─e263c8ca-d71c-4c43-90fd-8e9b5c4dce35
# ╟─2bda92e2-2b34-4afa-9303-d07520c7022a
# ╟─0398d0c0-05e4-4834-bed1-405d97263876
# ╟─95378129-1db8-4e48-b2a5-233832f56808
# ╟─4808e961-2a1e-4ae5-8eca-b6b26a2f67a0
# ╟─41004242-0ba9-41d0-b079-f6ccb19bd724
# ╟─bb6bf28d-9a6b-40ca-b28c-99a4e92f3252
# ╟─305a48d4-86d1-4309-bd4b-8f462663bd6d
# ╟─5ec9da2f-ed87-4927-8af1-44abfbf496a8
# ╟─80fa6b7b-dc48-440c-82da-97ea5e85f656
# ╟─66ad7fc5-9a59-47e0-9744-648fac9b6749
# ╟─e1ac8a81-585b-4595-94ff-28496c8d9c3f
# ╠═3fb28a94-8a34-45f7-bb72-6c07aa9841a3
# ╟─2efeb29a-71f3-4791-ae0b-b1bbe1f627dc
# ╟─bf885022-de9d-4bca-8288-b22c07007a85
# ╟─e14c4a92-62de-4556-9525-e05ff4dd03e9
# ╟─a7d9ce0f-9db9-485a-a56c-0e210bcb391c
# ╟─7a6f36b4-2d91-43b5-ba85-b1642371cd84
# ╟─0427d65a-a4f2-4514-b3e1-01a3f67685e0
# ╠═019259e2-532d-470e-99ed-242de888a846
# ╟─143654c3-02cd-41cb-8047-ddebd0c60f55
# ╟─f1294882-cbee-4b9f-88c1-cbb507d6e8f3
# ╟─ef50b36d-b9f2-479b-84dc-4bf3a3904f29
# ╟─bc7e7e91-0c60-48d0-832c-91441f095936
# ╟─2bde0c1e-776e-4c31-96ae-8cb7011c6cf0
# ╟─a8442bd1-478d-4a92-a935-b7bae41a2417
# ╠═035bed81-2cb3-45d1-aa15-1f0038fe22c9
# ╟─7217ed4a-8526-44b2-b7ee-cad616e78a34
# ╟─c15669d7-6f38-4d81-a0f8-b02b91bd024d
# ╠═642adb73-f7cd-4f93-9fcc-78e389be67e1
# ╠═fb7395eb-8a06-48dc-8b37-af14deab04b2
# ╟─bd1a4424-7abc-460a-9e36-e57592e76fbf
# ╟─71809ab0-c38d-440c-a1f9-0bc0c39781f7
# ╟─c6b1f451-0e2c-47e7-af93-c7b2fd304cb1
# ╠═172e54c9-fed4-452f-a250-7d3fa1804337
# ╟─452e4560-5acf-4696-9aa1-34b423370dd7
# ╟─6564ea12-baaf-46e5-9861-5690a5ef2e09
# ╟─913d2460-c36e-4066-9ac4-d883e468499e
# ╟─eb9ad94b-bdc1-49d3-91e8-d8dc1670ca49
# ╟─6100b888-2503-4e94-8241-52c1cbf15d18
# ╟─ab5b00ca-c0ad-44e7-9f96-0ba1372a4edb
# ╟─d16e980f-b0a0-4e76-8c4c-521a37ea5601
# ╟─03748a78-09fe-44b6-8fac-736eada78d15
# ╟─3a9e4b32-34cc-4c83-837f-dda432ea764d
# ╟─5022552a-c701-49b4-94de-b94ef4bf4864
# ╟─c80d38c0-6752-4017-a3c8-c54a2f6c1fad
# ╟─a9cb5cf9-8a48-4451-922c-b9d9cc266e1f
# ╟─7798d01e-373a-4858-b804-228159242101
# ╟─90a5ab07-1d5d-44e3-91d3-16afadf64ec6
# ╟─3221d531-1fab-418b-8ad9-bc543b1bdfb7
# ╟─91919d10-1302-446c-9f64-822b39fdff2a
# ╟─76cbafb6-24df-4937-967f-40d1967fe760
# ╟─ae1e465f-ad09-477f-add1-6abfa0ad97c8
# ╟─458ab998-d0f2-4be3-920b-47ff039af954
# ╟─bf6c6e3d-568d-43fa-940c-4d12dc982323
# ╟─a58195d5-c969-465c-86e6-eaf26b6d6d57
# ╟─3b1447c5-04a5-4d56-a87a-6553b65de216
# ╟─3d6262b8-8aec-4f26-a459-2f8d01d6be6b
# ╟─2b38a601-ecca-414a-b873-5a81081c37a2
# ╟─31eb4748-1ff5-4265-a2cd-17d83f2ad4b4
# ╟─c50fd20e-0a00-42f6-aeaf-c9909f0034fb
# ╟─eda71e41-9d14-4b0d-a49c-df7bb943a528
# ╟─5b1d6d05-37a8-4fec-ad5d-21304ae54d32
# ╟─6278f523-b1c6-4d0b-a0cc-3abba3bbcd81
# ╟─06059812-a00f-4658-993f-4b86ae3a8166
# ╟─266134a9-6503-41a7-b028-d8481412fb33
# ╟─f2627bb4-376e-412e-89ce-181669e479a9
# ╟─9453b3c5-2738-43bf-b475-955153154647
# ╟─96ebc13d-478d-4390-ae8c-0fa6414dcec2
# ╟─a0a70b85-2842-437a-b170-5f32ebff0f01
# ╟─24ad59d4-0591-4521-b033-a656f3df3989
# ╟─c58592c3-335c-4468-aac0-23ec3d28b455
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
