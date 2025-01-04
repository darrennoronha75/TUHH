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
	using PlutoUI,Images,TestImages,Interpolations,Plots,Random, LinearAlgebra, FFTW, ImageContrastAdjustment, Statistics, Noise, DSP, TOML, ImageTransformations,CoordinateTransformations, Rotations, Distributions, Deconvolution

hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))
	
	PlutoUI.TableOfContents()
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""
# 7. Image Processing - Image Restoration
[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ bdae42a3-8dbe-41ec-911a-89b087b26286
md"## 7.1 Introduction

In the last two lectures we  discussed all aspects of filtering in the spatial and the Fourier domain. We next look more general at image degradations and how they can be removed/reduced.

"

# ╔═╡ c0ff24f1-2bf2-4ee5-9e1a-cd986283caa1
md"### 7.1.1 Model for Degradation / Restoration

Until now we applied image enhancement without knowledge about the imaging process. A general model of the imaging process can be formulated as:

$g(\mathbf{r}) = h(\mathbf{r}) \ast f(\mathbf{r}) + \eta(\mathbf{r})$

where
*  $g(\mathbf{r})$ is the output image. It is the final result at the end of the imaging process.
*  $f(\mathbf{r})$ is the original image that is unknown. It is what we aim to reconstruct.
*  $h(\mathbf{r})$ is the kernel of the imaging process. Sometimes also called degradation function.
*  $\eta(\mathbf{r})$ is the noise function. This is a random function which means that it will be different when imaging the same object twice.
"

# ╔═╡ 5cab7bde-f0a8-4582-822f-1f9c2851da55
md"Equivalently, in frequency space, the imaging process can be written as

$\hat{g}(\mathbf{k}) = \hat{h}(\mathbf{k}) \hat{f}(\mathbf{k}) + \hat{\eta}(\mathbf{k})$
"

# ╔═╡ 2eeb0a2f-2f63-4d61-a25c-1d24532ac457
md"### 7.1.2 Reconstruction

Reconstruction or restoration is the process of calculating $f(\mathbf{r})$. There are different scenarios
1. In the best case both $h$ and a statistical model of $\eta$ is known. In that case we have a linear *inverse problem* that consists of undoing the convolution. This is called *deconvolution*.
2.  $h$ is known but $\eta$ is not. Then one can still perform a deconvolution but needs to guess the noise model.
3. Last case is that nothing is known. This is then a non-linear inverse problem that is much harder to solve. It is called a *blind deconvolution* and usually requires some sort of prior knowledge.


"

# ╔═╡ c9d97244-ed9c-422d-8f01-66669407169d
md"## 7.2 Noise Models

Any measurement, like capturing light with a digital camera, is affected by noise.  Noise can be modeled by a random variable in each pixel that follows a certain statistic. The statistic is described by the probability density function (PDF), which reports the probability that a certain value is measured.

Image noise can be either be correlated or uncorrelated. Uncorrelated means that the measurement in one pixel is independent of all other pixels. We here focus on uncorrelated noise, which is the the most relevant in image processing.
"

# ╔═╡ fd0841b8-a3c1-4a3c-8ff9-123daf90b83a
md"### 7.2.1 Probability Density Functions

We next discuss some important PDFs $p(z)$ occurring in practice. Two important characteristics of a random variable $Z$ are its expected value $E(Z)$ that is defined as

$\text{E}(Z) = \int_{-\infty}^{\infty} z \;p(z) \textrm{d}z$

and its variance

$\text{Var}(Z) = \int_{-\infty}^{\infty} (z- \text{E}(Z))^2 \;p(z) \textrm{d}z.$

Instead of the variance one often instead considers the standard deviation 

$\text{Std}(Z) = \sqrt{\text{Var}(Z)} = \sigma.$
"

# ╔═╡ 79908382-8a0b-4150-b10b-dd302a4710d5
md"##### Gaussian Noise

The PDF of Gaussian noise is given by

$p(z) = \frac{1}{\sqrt{2\pi}\sigma}\text{exp}\left(-\frac{(z-a)^2}{2\sigma^2} \right).$

Its expected value is $\text{E}(Z) = a$ the standard deviation is $\text{Std}(Z)=\sigma$.
"

# ╔═╡ 3c0a5a68-e8ff-4dd5-814c-72cc77aaf130
let
	z=range(-2,10,length=100)
	gaussian(z,σ,μ) = 1/(sqrt(2*pi)*σ) * exp(-(z-μ)^2/(2σ^2))

	σ = 1; μ = 5
	plot(z, gaussian.(z,σ,μ), label=nothing,lw=2, xlabel="z", ylabel="p(z)")
end

# ╔═╡ 18e6344f-6cdb-4405-be89-51acaacb9af8
md"##### Uniform Noise

The PDF of uniform noise is given by

$p(z) = \begin{cases}
 \frac{1}{b-a}& \text{if} \quad a\leq z\leq b \\
 0 & \text{otherwise}
\end{cases}$
with the expected value $\text{E}(Z) = \frac{a+b}{2}$ and the standard deviation $\text{Std}(Z) = \sqrt{\frac{(b-a)^2}{12}}$."

# ╔═╡ a6443b7c-25e3-4d8e-a466-e3fcb0d677b7
let
	z=range(-2,10,length=100)

	uniform(z,a,b) = a<=z<=b ? 1/(b-a) : 0

	a = 3; b = 3
	

	plot(z, uniform.(z,a,b+a), label=nothing,lw=2,xlabel="z", ylabel="p(z)")
end

# ╔═╡ d3bbc63a-0053-4812-94dc-61e446c8ee48
md"##### Rayleigh Noise

The PDF of [Rayleigh noise](https://en.wikipedia.org/wiki/Rayleigh_distribution) is given by

$p(z) = \begin{cases} \frac{2}{b}(z-a)\text{exp}\left(-\frac{(z-a)^2}{b} \right) & z \geq a \\
0 & z< a
\end{cases}$

with the expected value $\text{E}(Z) = a+ \sqrt{\pi b/4}$ and the standard deviation $\text{Std}(Z) = \sqrt{\frac{b(4-\pi)}{4}}$.

"

# ╔═╡ 1d9db32d-e7b5-4fa8-98b7-dc54d7179d4d
let
	z=range(-2,10,length=100)

	rayleigh(z,a,b) = z<a ? 0 : 2/b*(z-a) * exp(-(z-a)^2/(b))
	
	a = 3; b = 3
	
    plot(z, rayleigh.(z,a,b), label=nothing,lw=2,xlabel="z", ylabel="p(z)")
end

# ╔═╡ 0c48cf3d-d252-457c-a2c4-c52699441545
md"It features two important characteristics that distinguish it from the Gaussian PDF:
1. It has a value $a$ below which no noise can occur. 
2. It is not symmetric and can model a bias in one direction.

An example of such noise is a detector that counts events. It cannot go below zero, since the number of events is always positive. Furthermore the noise is higher for a low number of events, while it is lower for a high number of events.

"

# ╔═╡ 7092b4c7-040b-469b-b6af-7cf060539c86
md"
##### Salt and Pepper Noise

[Salt and pepper noise](https://en.wikipedia.org/wiki/Salt-and-pepper_noise), also named bipolar noise is not an additive noise since it includes saturation effects. In particular it may happen within the electronics during digitization where a pixel is either mapped to the highest or the lowest value ($0$ or $2^k-1$ for a $k$ bit digitizer). This also explains why the noise is not additive since you can change the value of the underlying image but the noise pixel will still be mapped to $0$ or $2^k-1$.

Keeping that in mind we can still write the PDF in the form

$p(z) = \begin{cases} P_a & \text{for} \; z= a \\
P_b & \text{for} \; z= b \\
0 & \text{otherwise}.
\end{cases}$

"

# ╔═╡ 7856b3a3-b7fb-476b-840b-fd2576f36e21
md"The following illustrates all four PDFs in a single figure for comparison:"

# ╔═╡ 7e8357b7-f471-4579-b817-4d74578d175e
begin
	z=range(-2,10,length=100)
	gaussian(z,σ,μ) = 1/(sqrt(2*pi)*σ) * exp(-(z-μ)^2/(2σ^2))
	rayleigh(z,a,b) = z<a ? 0 : 2/b*(z-a) * exp(-(z-a)^2/(b))
	uniform(z,a,b) = a<=z<=b ? 1/(b-a) : 0
	bipolar(z,a,b) = abs(z-a) < 0.05 || abs(z-b) < 0.03 ? 0.5 : 0
	σ = 1; μ = 5
	a = 3; b = 3
	
	plot(
	  plot(z, gaussian.(z,σ,μ), label=nothing,lw=2,title="Gaussian Noise",xlabel="z", ylabel="p(z)"),
	  plot(z, rayleigh.(z,a,b), label=nothing,lw=2,title="Rayleigh Noise",xlabel="z", ylabel="p(z)"),
	  plot(z, uniform.(z,a,b+a), label=nothing,lw=2,title="Uniform",xlabel="z", ylabel="p(z)"),
	  plot(z, bipolar.(z,a,b+a), label=nothing,lw=2,title="Bipolar",xlabel="z", ylabel="p(z)"),
	  size=(800,450), layout=(2,2)
	)
end

# ╔═╡ 383f07a3-fca6-458c-9412-dd3febd6e002
let
	z=range(-2,10,length=100)
	a = 3; b = 3
	
    plot(z, bipolar.(z,a,b+a), label=nothing,lw=2,xlabel="z", ylabel="p(z)")

end

# ╔═╡ e8644415-5694-4775-8e93-062c2224122f
md"Let us next look at some images effected by these noise models and look at the histograms:"

# ╔═╡ c7fea193-fcb0-4777-944a-7a0c67491385
begin
	function simpleimage(N)
		I =  0.35.*[ (ix-N÷2)^2 + (iy-N÷2)^2 < (N÷3)^2 for ix=1:N, iy=1:N] +
		    0.35.*[ abs(ix-N÷2) < ((2*N)÷5) && abs(iy-N÷2) < ((2*N)÷5)  for ix=1:N, iy=1:N]
		return I
	end
	
	N = 256
	I = simpleimage(N)
	N2 = 0.08*randn(N,N)
	N1 = 0.25*rand(N,N)
	N3 = 0.25*rand(Rayleigh(0.35), N,N)
	ISP = salt_pepper(I)
	
	plot(
		heatmap(Gray.(I+N2), title="Gaussian"),
		histogram(vec(I+N2),bins=range(-0.5,1.5,length=100)),
		heatmap(Gray.(I+N1), title="Uniform"),
		histogram(vec(I+N1),bins=range(-0.5,1.5,length=100)),
		heatmap(Gray.(I+N3), title="Rayleigh"),
		histogram(vec(I+N3),bins=range(-0.5,1.5,length=100)),
		heatmap(Gray.(ISP), title="Salt and Pepper"),
		histogram(vec(ISP),bins=range(-0.5,1.5,length=100)),
		layout=(4,2), size=(800,1000)
	)
end

# ╔═╡ a1d8f0f8-a871-459c-a7cc-216e543fd5af
note(md"In practice it depends a lot on the application what type of noise one gets. The more you know about the noise distribution, the better you can handle it. In most cases a Gaussian distribution arises. It is thus quite common to assume Gaussian noise even if one has no precise knowledge about the concrete noise distribution.")

# ╔═╡ 7522fb2b-ed2f-4376-8998-ceea7417b47f
md"### 7.2.2 Noise in Frequency Space

One interesting question is how the noise translates into the Fourier space. In case of Gaussian uncorrelated noise, the noise carries over along the entire spectral line. In other words: Noise contains all frequencies with the same likelihood. We call this [white noise](https://en.wikipedia.org/wiki/White_noise) motivated by the fact, that light usually is of this form.

Let us verify this using a simple code example:
"

# ╔═╡ 783c6626-a109-4203-b0d7-89b89cd00c35
begin

noise = randn(1000)
noiseFT = fft(noise)
	
plot(plot(noise, title="Spatial Domain", label=nothing,c=1),
	 plot(real.(noiseFT), title="Fourier Domain (real)", label=nothing,c=2), 
	 plot(real.(noiseFT), title="Fourier Domain (imag)", label=nothing,c=3),
	plot(abs.(noiseFT), title="Fourier Domain (abs)", label=nothing,c=4),
		layout=(2,2), size=(800,400), lw=2)	
end

# ╔═╡ f67126f4-22ef-4f53-bfcb-49c9baa3d739
md"The lower right plot shows the quantity $|\hat{f}(u)|$, which we call the *power spectrum* of $\hat{f}$. It is usually considered to quantify the amount of noise in frequency space."

# ╔═╡ e49c85c5-7c3d-4212-b435-0a7b3478e9ea
md"
#### Colored Noise
Noise is not always white but is can have different [color](https://en.wikipedia.org/wiki/Colors_of_noise). Different color here means that the power spectrum varies depending on frequency as is shown in the following image."

# ╔═╡ e57c0c47-1e29-4fd9-b4e9-97ae81487d91
LocalResource("img/The_Colors_of_Noise.png", :width=>600)

# ╔═╡ e4a96bad-8ae9-4c9a-b49e-0122e22e1121
md"Such noise appears in  electronical applications because of the nature of certain circuits. [Thermal noise](https://en.wikipedia.org/wiki/Johnson%E2%80%93Nyquist_noise), that occurs in all resistors is white (Gaussian) noise."

# ╔═╡ 1b6ac67a-7d66-4a85-b269-42a9855b69d5
md"### 7.2.3 Determining Noise Statistics

There are different ways to determine the noise statistics if it is not known from a physical model.

##### With Access to Background Images

Let us have a look again at the imaging equation:
 
$g(\mathbf{r}) = h(\mathbf{r}) \ast f(\mathbf{r}) + \eta(\mathbf{r})$ 

Quite often one has the possibility to capture an *empty* or *background* image

$g_\text{empty}(\mathbf{r}) = h(\mathbf{r}) \ast 0(\mathbf{r}) + \eta(\mathbf{r}) = \eta(\mathbf{r})$

where $0(\mathbf{r})$ is the function that maps all spatial positions to zero. Having this one can perform a statistical analysis if(!) the mean and variance is constant over the entire image. If that is not the case one can capture a series of images $g^l_\text{empty}(\mathbf{r})$ and perform the statistical analysis along the samples $l$ for each pixel $\mathbf{r}$ independently.


"

# ╔═╡ e3651bb5-3d8d-4368-95f4-c17f900a68d1
md"
##### Without Access to Background Images

Quite often one just has the image $g$ and no additional background image. In that case one can still estimate the noise statistics:
* In the spatial domain one can seek for a region $R_{\mathbf{r}}$, which appears to be (almost) constant. Then, within this constant area one can derive the noise variance. The mean of the background can be determined only if the selected area contains background only.
* In case of a smooth but not constant foreground in the region $R_{\mathbf{r}}$ it is possible to derive a linear or polynomial model of the signal using [regression methods](https://en.wikipedia.org/wiki/Regression_analysis). Let this model be $y$. Then the noise variance can be estimated from $g(R_{\mathbf{r}}) - y(B_{\mathbf{r}})$.
* Finally, it is often easy to separate noise from the image entirely in Fourier space. To this end, one performs the statistical analysis in an outer region of the Fourier space. This is based on the fact that natural images usually decay rapidly in Fourier space while the noise level is constant. 
"

# ╔═╡ 19649292-4da6-47f8-8df6-7d39be4a3e9c
md"
##### Statistical Analysis

The [mean](https://en.wikipedia.org/wiki/Arithmetic_mean) can be calculated from sampled values within the region $R_\mathbf{r}$ by

$\text{E}(f(R_\mathbf{r})) = \frac{1}{|R_\mathbf{r}|}\sum_{\mathbf{r}' \in R_\mathbf{r}} f(\mathbf{r}').$

Here, the region $R_\mathbf{r}$ can also be the entire image.

The [variance](https://en.wikipedia.org/wiki/Variance) can be calculated by

$\text{Var}(f(R_\mathbf{r})) = \frac{1}{|R_\mathbf{r}|}\sum_{\mathbf{r}' \in R_\mathbf{r}} ( f(\mathbf{r}') - \text{E}(f(R_\mathbf{r})))^2.$


"

# ╔═╡ 4538fc7b-c622-4d17-8305-73556fc726da
md"## 7.3 Noise Reduction

We first consider the case that the imaging system is not affected by the degradation function $h$, i.e. we assume that $h=\delta$ and in turn the imaging equations in spatial and Fourier domain can be expressed as


$g(\mathbf{r}) = f(\mathbf{r}) + \eta(\mathbf{r})$
$\hat{g}(\mathbf{k}) =  \hat{f}(\mathbf{k}) + \hat{\eta}(\mathbf{k})$


The first idea could be to subtract $\eta(\mathbf{r})$ from $g(\mathbf{r})$ but this  of course does not work since $\eta(\mathbf{r})$ is a random variable and in turn we can only know the mean and variance from it but not the concrete instance that affected $g(\mathbf{r})$.

"

# ╔═╡ e5784a30-07b1-4782-8007-6f0eceba9818
md"### 7.3.1 Simple Filtering

In the case that one has a series of measurements

$g_l(\mathbf{r}) = f(\mathbf{r}) + \eta_l(\mathbf{r}) \quad l=1,\dots,L$

one can simply average over the elements of the series. This is often the case when $g$ is a temporal function and one can *block average* over time:

$\overline{g}(\mathbf{r}) =\frac{1}{L}\sum_{l=1}^{L }g_l(\mathbf{r})$

Of course this requires that the image $f$ is static for $l=1,\dots,L$.
"

# ╔═╡ 535089bc-0a97-4d9e-b4ac-e37f241bb01f
note(md"What we described in a discrete setting here is the same as the integration time or in photography the [exposure time](https://en.wikipedia.org/wiki/Shutter_speed). The longer one exposures, the more light reaches the detector and in turn the noise is reduced. If the image moves, however, one gets motion artifacts.")

# ╔═╡ d75c8269-ef70-48b4-b8aa-0fca2d7614cc
md"In case that  only a single image is available one cannot average over a series and instead needs to average in space. This can be done using the filtering techniques we discussed in the last two lectures. Recall that applying a Gaussian filter is a good way when the noise has a Gaussian noise distribution (or uniform) while salt and pepper noise is better handled with a median filter."

# ╔═╡ dc8d3c44-7afd-4233-91e4-c5ae9448b6f3
note(md"The kernel width of the averaging filter needs to be adapted to the noise level $\sigma$ in the image. ")

# ╔═╡ 33d604d3-8f6c-42cc-9e5a-f2efadb853a4
md"### 7.3.2 Adaptive Filtering

One drawback of the regular spatial filtering is that the filter kernel is spatially independent. This leads to the situation that regions with strong image intensity are treated the same way as regions with low image intensity although the signal-to-noise ratio is higher in the first case.

To address this issue *adaptive filters* can be used. These filters have the ability to calculate local noise statistics and then change the amount of averaging based on that. These filters are obviously not *shift-invariant* anymore and we loose the connection to the Fourier space. In addition adaptive filters are often *non-linear*.
"

# ╔═╡ 05780b18-b8a2-479d-9361-6f955450a8f9
note(md"Adaptive filters share some ideas with filtering methods that employ neural networks.")

# ╔═╡ 4c70a69a-0378-4df4-afd6-051ba60fe015
md"#### Adaptive Local Noise Reduction Filter

There are many adaptive filters, here we present a local noise reduction filter that is based on the box averaging filter. Of course it can be generalized to other noise reduction filters.

Two ideas to make the filter adaptive are
1. Change the filter kernel size based on the local noise.
2. Use a convex combination of filtered and unfiltered image based on the local noise.

We chose the second strategy here. Our filter is a *sliding window* filter that operates on a certain region $R_\mathbf{r}$ at a time. What we now do is to relate the standard deviation of the local patch $\sigma_\text{L}$ to the standard deviation of the entire image $\sigma_\text{G}$. The algorithm needs the later as an input parameter, which can be estimated with the methods discussed earlier.
"

# ╔═╡ 955b0c97-6729-4c15-9287-804a757ed853
md"
The algorithm then distinguishes the following cases:
* if $\sigma_\text{G} \approx \sigma_\text{L}$ global and  local noise are similar and we can  average without problems since the underlying image is within a smooth region.
* if $\sigma_\text{G} \ll \sigma_\text{L}$ the underlying image $f$ has large variations e.g. due to an edge. In those cases we want do use the local value $g(\mathbf{r})$ without averaging.

In this way we achieve that edges are preserved, while surface areas are averaged. The updated value is then calculated by

$g_\text{filtered}(\mathbf{r}) = g(\mathbf{r}) - \text{min}\left(\frac{\sigma_\text{G}^2}{\sigma_\text{L}^2},1\right) \left(g(\mathbf{r}) - \text{E}(g(R_\mathbf{r})  \right)$


One can see that we added a special handling for the case $\sigma_\text{L} \ll \sigma_\text{G}$ since otherwise, the filtered value would return non-valid results. This operation makes the filter non-linear.
"

# ╔═╡ b73072bd-6a67-435a-9e0c-daf6fceb4cd9
md"The following shows the adaptive filter in action:"

# ╔═╡ d854dbcf-f00e-45e2-b4eb-bc39a2464a8e
begin
	function adaptive_local_noise_reduction_inner(img, σG)
		N = size(img)
		M = N.÷2
		m = mean(img)
		g = img[M[1],M[1]]
		σL = var(img)
		s = (σG/σL)^2
		s = min(s,1.0)
		return g - s*(g-m) 
	end

	function adaptive_local_noise_reduction(img, filter_size, σG)
		
	    mapwindow( im-> adaptive_local_noise_reduction_inner(im,σG), img, filter_size)
	end	
	
	
	imgpep = Float64.(Gray.(testimage("peppers_gray")))
	imgNoise = randn(size(imgpep)...)*0.1
	imgpepNoise = imgpep .+ imgNoise
	
	M = (9,9)
	
	plot(
		heatmap(Gray.(imgpep), title="original"),
		heatmap(Gray.(imgpepNoise),title="noisy"),
		heatmap(Gray.( imfilter(imgpepNoise, 1/prod(M)*ones(M...))),title="box filter"),
		heatmap(Gray.( adaptive_local_noise_reduction(imgpepNoise, M, var(imgNoise))),title="adaptive filter"),
		
		layout=(2,2), size=(800,800)
	)	
end

# ╔═╡ 0eb60af8-e5ec-45c7-9ec7-5e6fbadc8538
md"One can clearly see that the image is less blurred although the noise is reduced the same amount as for the box filter."

# ╔═╡ 3110daa7-096f-4540-9ced-8d97036db9b7
md"### 7.3.3 Periodic Noise Filtering

We next focus on non-white, spatially dependent noise, which has a local support in the Fourier space. Let us have a look at the following distorted image:
"

# ╔═╡ fba2a177-93d8-4e28-99d1-6fc34a8222c4
begin
  img = Float64.(testimage("fabio_gray"));
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

# ╔═╡ 86688652-33f2-44e7-ae43-0d4d166e2893
let
	
imgFT = fftshift(fft(img))
		
noiseFT = zeros(ComplexF64, size(imgFT)...)
k = 70
N = 256
noiseFT[k,k] = maximum(abs.(imgFT))
noiseFT[k,N-k+1] = maximum(abs.(noiseFT))

imgNoiseFT = imgFT + noiseFT
		
imgNoise = real.(ifft(ifftshift(imgNoiseFT)))
	
plot(
  heatmap(Gray.(img),title="image space"),
  heatmap(Gray.(ftAmpDisplay(img)),title="Fourier space amplitude"),
  heatmap(Gray.(imgNoise),title="image space"),
  heatmap(Gray.(ftAmpDisplay(imgNoise)),title="Fourier space amplitude"),		
  layout=(2,2), size=(800,800)
)
	
end

# ╔═╡ c4fe042a-362a-43a7-b599-1052434a0580
md"One can clearly see that there is an overlaying periodic pattern that degrades the image quality. Such a pattern is very common if one, for instance, digitizes some printed raster image.

In Fourier space one can clearly identify the peaks containing the noise component.
"

# ╔═╡ ee77994c-af70-4b66-b3c9-89f79f28a188
md"
##### Band-Stop Filter

In order to remove such periodic noise we can apply a so called *band-stop* or *notch filter*. Basically one can use a high pass filter and  move the center to a different frequency. For instance a Gaussian band-stop filter can be written as

$\hat{h}_\text{BS}^{\sigma, u_0, v_0}(u,v) = 1 - \text{exp}\left(-\frac{(u-u_0)^2+(v-v_0)^2}{2\sigma^2} \right)$

Periodic noise always occurs not only at frequency $(u_0,v_0)$ but also at $(-u_0,-v_0)$ since the image $f$ is real and therefore we have the symmetry 

$\hat{f}(u_0,v_0) = \overline{\hat{f}(-u_0,-v_0)}.$

But one usually also see the signal at $(u_0,-v_0)$ and $(-u_0,v_0)$.
Consequently, the applied band-stop should filter out the signal in all four quantrants:

$\begin{align}
\hat{h}_\text{BS,symmetric}^{\sigma, u_0, v_0}(u,v) = 1 &- \text{exp}\left(-\frac{(u-u_0)^2+(v-v_0)^2}{2\sigma^2} \right) - \text{exp}\left(-\frac{(u+u_0)^2+(v+v_0)^2}{2\sigma^2} \right) \\ &- \text{exp}\left(-\frac{(u-u_0)^2+(v+v_0)^2}{2\sigma^2} \right) - \text{exp}\left(-\frac{(u+u_0)^2+(v-v_0)^2}{2\sigma^2} \right)
\end{align}$

"

# ╔═╡ be6c44d0-7385-4963-af24-a2f41024321b
md"Our example before was distorted by two periodic frequencies and in turn we need to combine four band-stop filters. 

The following shows the developed band-stop filter in action:
"

# ╔═╡ 73200fe7-def9-41ac-92c6-378a2138284d
let

	
imgFT = fftshift(fft(img))
		
noiseFT = zeros(ComplexF64, size(imgFT)...)
k = 70
N = 256
noiseFT[k,k] = maximum(abs.(imgFT))
noiseFT[k,N-k+1] = maximum(abs.(noiseFT))

imgNoiseFT = imgFT + noiseFT
	
# now we apply the filter:
	
u0,v0= N÷2-k,N÷2-k
	
D=3
bandStop1 = [ 1-exp(-(((u-div(N,2)-u0))^2+(v-div(N,2)-v0)^2)/(2*D^2))-exp(-(((u-div(N,2)+u0))^2+(v-div(N,2)+v0)^2)/(2*D^2)) for u=1:N, v=1:N] 
bandStop2 = [ 1-exp(-(((u-div(N,2)+u0))^2+(v-div(N,2)-v0)^2)/(2*D^2))-exp(-(((u-div(N,2)-u0))^2+(v-div(N,2)+v0)^2)/(2*D^2)) for u=1:N, v=1:N] 

bandStop = bandStop1.*bandStop2
	
bandStop ./= maximum(bandStop)
		
imgNoise = real.(ifft(ifftshift(imgNoiseFT)))
imgFiltered = real.(ifft(ifftshift(imgNoiseFT.*bandStop)))
	
plot(
  heatmap(Gray.(imgNoise),title="image space"),
  heatmap(Gray.(ones(N,N)),title="filter"),
  heatmap(Gray.(ftAmpDisplay(imgNoise)),title="Fourier space amplitude"),
  heatmap(Gray.(imgFiltered)),
  heatmap(Gray.(bandStop)),
  heatmap(Gray.(ftAmpDisplay(imgFiltered))),		
  layout=(2,3), size=(800,600)
)
	
end

# ╔═╡ cf386a0c-aa32-4328-a7c2-fa20141b5f9b
note(md"Periodic degradations often are the result of interference, which sometimes cannot be avoided. The Moire effect is an example of an interference resulting in periodic patterns that can be removed by band-stop filtering.")

# ╔═╡ 9585d9db-bbd3-4483-9d91-049150bce1d0
note(md"We have not discussed how to determine the frequencies of the periodic noise. In case that they are clearly apart from the center of the Fourier space once usually can determine them by thresholding of the power spectrum.")

# ╔═╡ de213212-e527-4bd5-8d8d-0cbc4f7fbdd2
md"## 7.4 Obtaining the Degradation Function

We  finally switch to the general setting

$g(\mathbf{r}) = h(\mathbf{r}) \ast f(\mathbf{r}) + \eta(\mathbf{r}).$

First we discuss how to determine the kernel $h$. Depending on the application there are different approaches here:
"

# ╔═╡ bbb22037-c1a4-4e84-a4a9-624556d41381
md"### 7.4.1 Estimation by Experimentation

In case that we have access to the underlying experiment  we can perform the imaging with an $f(\mathbf{r})$ that we know and then determine $h$ by experimentation. If we, for instance insert a dirac delta into the imaging equation we obtain

$g(\mathbf{r}) = h(\mathbf{r}) \ast \delta(\mathbf{r}) + \eta(\mathbf{r}) = h(\mathbf{r}) + \eta(\mathbf{r})$

Since a real delta distribution cannot be realized in practice one should divide this equation by the area of the applied sample. The noise component $\eta(\mathbf{r})$ can often be ignored since the delta sample has a high intensity and is much larger than $\eta$. Furthermore, since we have access to the experiment itself we can also measure a series of images and apply averaging. Finally, if the kernel is still noisy we can also smooth the kernel in spatial domain.
"

# ╔═╡ 3e8330ce-1933-407f-a598-9dbb741163d5
md"### 7.4.2 Estimation by Observation

The second method is similar but has no access to the experiment itself. Instead only a distorted image $g$ is available. In that case one can look within the image for local structures like an edge, where the true function $f(\mathbf{r})$ can be estimated by semantic knowledge about the data. Then lets focus on the local region $R_\mathbf{r}$ and lets assume that we derive a local *unblurred* image $f_\text{unblurred}$ just by the knowledge that there needs to be an edge or a dot. Then we can estimate $h$ in Fourier space by


$\hat{h}(\mathbf{k}) = \frac{\hat{g}(\mathbf{k})}{\hat{f}_\text{unblurred}(\mathbf{k})}$

where all quantities are restricted to the local region $R_\mathbf{r}$.
"

# ╔═╡ 0a42a943-5767-444b-b0dd-78d086735fe5
note(md"We only roughly sketched this method.  To end up at a stable method one needs to postprocess the kernel and apply further prior knowledge. For instance isotropy of the kernel can be assumed when only an edge in a single direction is available.")

# ╔═╡ 13e25dde-d9de-4cd4-a724-fde5c3f06592
md"### 7.4.3 Estimation by Modelling

The third method does not try to derive the kernel in a data-driven fashion but instead uses a model. For a large class of applications (i.e. photography), the kernel will have the form of a Gaussian kernel and we can use the model

$\hat{h}_\text{Gaussian}^\sigma(u,v) = \text{exp}\left(-\frac{u^2+v^2}{2\sigma^2} \right)$

for the kernel. Now the only unknown parameter is the kernel width $\sigma$. This can then be estimated by performing several reconstructions (see section about deconvolution) and inspecting the resulting image quality.
"

# ╔═╡ 1d71f0b3-0233-4cb2-af04-5ea516aae2e2
md"## 7.5 Deconvolution 

Now we assume that we know the kernel $h$ and aim to solve


$g(\mathbf{r}) = h(\mathbf{r}) \ast f(\mathbf{r}) + \eta(\mathbf{r})$

or equivalently


$\hat{g}(\mathbf{k}) = \hat{h}(\mathbf{k}) \hat{f}(\mathbf{k}) + \hat{\eta}(\mathbf{k})$

What we can directly see is that the solution is much easier in Fourier space since a scalar multiplication can be easier  undone than a convolution.
"

# ╔═╡ c155cd3a-28ac-4895-90f1-4e8d457c7555
md"### 7.5.1 Naive Deconvolution

If we  ignore the noise we can perform the deconvolution by

$\hat{f}_\text{deconv}(\mathbf{k})= \frac{\hat{g}(\mathbf{k})}{ \hat{h}(\mathbf{k}) }$

This has of course the issue that we might divide by zero but let us for the moment assume that this does not happen since $\hat{h}(\mathbf{k})$ is non-zero. 

The following example shows what happens when using this approach:"

# ╔═╡ 53ce5f41-00b9-4fe5-ae06-4ba1bf67f8ca
begin
function gaussian_kernel(σ,m=2σ) 
  h = [ exp(-((x-m/2)^2+(y-m/2)^2)/(2*σ^2)) for x=1:m, y=1:m] 
  return h./maximum(vec(h))
end
	
img_ = channelview(testimage("cameraman"))

blurring_ft = gaussian_kernel(20,512) 
# Create additive noise
noise_ = rand(Float64, size(img_))*0.1
# Fourier transform of the blurred image, with additive noise
blurred_img_ft = fftshift(blurring_ft) .* fft(img_) .+ fft(noise_)
# Get the blurred image from its Fourier transform
blurred_img = real(ifft(blurred_img_ft))
# Get the blurring kernel in the space domain
blurring = ifft(fftshift(blurring_ft))
blurringNorm = fftshift(abs.(blurring) ./ maximum(abs.(blurring)))
	
# naive deconvolution
deconv_img_ft = blurred_img_ft ./ fftshift(blurring_ft) 
deconv_img = real(ifft(deconv_img_ft))

	
plot(heatmap(Gray.(img_), title="original"), 
	 heatmap(Gray.(blurred_img), title="blurred"),
	 heatmap(Gray.(blurringNorm), title="kernel"), 
	 heatmap(Gray.(deconv_img), title="naive deconvolved"),
	 layout=(2,2), size=(800,700))
end

# ╔═╡ 73b3adf6-01fe-4d9a-b6fa-ea8190307a04
md"##### Observation
* The deconvolved image looks looks completely wrong. Why?


The reason is that we need to take the noise into account. If we do this, the naive convolution looks like this:


$\hat{f}_\text{deconv}(\mathbf{k}) =  \frac{\hat{g}(\mathbf{k})}{ \hat{h}(\mathbf{k}) }  = \frac{\hat{h}(\mathbf{k}) \hat{f}(\mathbf{k})}{ \hat{h}(\mathbf{k}) } + \frac{\hat{\eta}(\mathbf{k})}{ \hat{h}(\mathbf{k}) } = \hat{f}(\mathbf{k}) + \frac{\hat{\eta}(\mathbf{k})}{ \hat{h}(\mathbf{k}) }$

Thus, the original image $\hat{f}(\mathbf{k})$ is overlaid by the noise component $\frac{\hat{\eta}(\mathbf{k})}{ \hat{h}(\mathbf{k}) }$. Now the bad thing is that we divide the noise by our kernel function $\hat{h}(\mathbf{k})$, which has very small values in outer Fourier space regions. Thus the noise is *amplified* by the deconvolution. This amplification can be so strong that the original image is not visible anymore.
"

# ╔═╡ b5502573-0511-4389-8809-79d5b1651516
md"### 7.5.2 Wiener Deconvolution

To solve the issue with the noise amplification we need to apply a technique called **regularization**. Regularization means that we still try to solve the underlying inverse problem but do so without amplifying the noise. Let's first write the naive deconvolution formula as

$\hat{f}_\text{deconv}(\mathbf{k})= \hat{g}(\mathbf{k}) \hat{w}(\mathbf{k})$

with $\hat{w}(\mathbf{k}) = \frac{1}{\hat{h}(\mathbf{k})}$. The naive deconvolution is thus just a filtering operation with an inverse transfer function.

What we now want to do is to prevent the filter kernel to *blow up*. This happens if
* the term $\hat{h}(\mathbf{k})$ gets very small and
* the term $\hat{g}(\mathbf{k})$ is dominated by noise
Based on these two properties one can derive the Wiener filter

$\hat{w}_\text{wiener}(\mathbf{k})= \frac{1}{\hat{h}(\mathbf{k})} \left( \frac{|\hat{h}(\mathbf{k})|^2}{|\hat{h}(\mathbf{k})|^2 + \frac{|\hat{\eta}(\mathbf{k})|}{|\hat{f}(\mathbf{k})|} }  \right) =  \frac{1}{\hat{h}(\mathbf{k})} \left( \frac{|\hat{h}(\mathbf{k})|^2}{|\hat{h}(\mathbf{k})|^2 + \frac{1}{\text{SNR}(\mathbf{k})} }  \right)$


with the signal-to-noise ratio $\text{SNR}(\mathbf k) = \frac{|\hat{f}(\mathbf{k})|}{|\hat{\eta}(\mathbf{k})|}$.

"

# ╔═╡ 39348fce-b360-4f23-bf8c-8d2d28712328
md"
#### Interpretation

The interpretation is as follows: 
* If the SNR is high, the term in brackets is close to 1 and the filter acts as a regular deconvolution kernel.
* If the SNR is small, the term $\frac{1}{\text{SNR}(\mathbf{k})}$ becomes dominant and in turn the entire bracket approaches $0$ if $\hat{h}$ gets small. This means that the noise amplification is prevented.
"

# ╔═╡ fe29c5c1-a6ca-4de5-ba74-83aa1ed5ddbb
md"Let us apply Wiener deconvolution to our example before:"

# ╔═╡ d49beeaa-1fcf-4f01-b355-0062b0cb636f
begin
polished = wiener(blurred_img, img_, noise_, blurring)

plot(heatmap(Gray.(img_), title="original"), 
	 heatmap(Gray.(blurred_img), title="blurred"),
	 heatmap(Gray.(polished), title="wiener"), 
	 layout=(1,3), size=(800,300))
end

# ╔═╡ 8cf1edcb-2df9-423f-a775-87c1daa3a576
md"One can see that the deconvolved image now indeed looks similar to the original one. It is not perfect but the spatial resolution is clearly improved while only the noise is only slightly increased."

# ╔═╡ f70cd513-8709-4481-95c8-796ee6405241
md"#### Unknown Parameters

The Wiener filter requires the noise image $|\hat{\eta}(\mathbf{k})|$ and the power spectrum of the undegraded image $|\hat{f}(\mathbf{k})|$ as the input. The noise image can usually be replaced by a constant $K$ in case that the noise is white. $K$ can be estimated from noise statistics (discussed before) or chosen to be a user defined parameter. $|\hat{f}(\mathbf{k})|$ is usually approximated by $|\hat{g}(\mathbf{k})|.$ Combining this we can write the Wiener deconvolution filter as

$\hat{w}_\text{wiener}^\text{impl 1}(\mathbf{k})= \frac{1}{\hat{h}(\mathbf{k})} \left( \frac{|\hat{h}(\mathbf{k})|^2}{|\hat{h}(\mathbf{k})|^2 + \frac{K}{|\hat{g}(\mathbf{k})|} }  \right).$

Instead one can also choose a constant term for the SNR ending up with

$\hat{w}_\text{wiener}^\text{impl 2}(\mathbf{k})= \frac{1}{\hat{h}(\mathbf{k})} \left( \frac{|\hat{h}(\mathbf{k})|^2}{|\hat{h}(\mathbf{k})|^2 + \lambda }  \right).$

"

# ╔═╡ 33c46f9e-e582-4691-ac42-efeeec415ac9
md"The following slider allows to adjust $K$ and look at the resulting deconvolved image: $(@bind K Slider((range(1,10,length=10)); default=6, show_value=true)) "

# ╔═╡ 03b095af-d57e-41fe-8754-b4c0fdfa9a74
begin
polished2 = wiener(blurred_img, img_, 1e-3*10^K, blurring)
	
plot(heatmap(Gray.(img_), title="original"), 
	 heatmap(Gray.(blurred_img), title="blurred"),
	 heatmap(Gray.(polished2), title="wiener"), 
	 layout=(1,3), size=(800,300))
end

# ╔═╡ af031fba-7035-4fa1-a9d4-c4d181d294f8
note(md"Wiener filtering is related to [Tikhonov regularization](https://en.wikipedia.org/wiki/Tikhonov_regularization). Tikhonov regularization is equivalent to Wiener filtering if the imaging operator is linear and shift invariant.")

# ╔═╡ a55e12ae-058e-4bac-8bb1-594e475ef3f1
md"## 7.6 Wrapup

In this lecture we have learned that images are degraded by an kernel $h$ and noise $\eta$. The more we know about both terms, the better we can reconstruct the original image. Since both terms are commonly unknown, they need to be estimated in some way. Prior to image reconstruction one thus first needs to *analyse* the image in detail and based on that chose an adequate strategy for image improvement.

"

# ╔═╡ Cell order:
# ╟─b17eb2a9-d801-4828-b0cd-5792527a10d8
# ╟─c16597c4-9cf9-4a7d-966c-6b6b4aa4765b
# ╟─bdae42a3-8dbe-41ec-911a-89b087b26286
# ╟─c0ff24f1-2bf2-4ee5-9e1a-cd986283caa1
# ╟─5cab7bde-f0a8-4582-822f-1f9c2851da55
# ╟─2eeb0a2f-2f63-4d61-a25c-1d24532ac457
# ╟─c9d97244-ed9c-422d-8f01-66669407169d
# ╟─fd0841b8-a3c1-4a3c-8ff9-123daf90b83a
# ╟─79908382-8a0b-4150-b10b-dd302a4710d5
# ╟─3c0a5a68-e8ff-4dd5-814c-72cc77aaf130
# ╟─18e6344f-6cdb-4405-be89-51acaacb9af8
# ╟─a6443b7c-25e3-4d8e-a466-e3fcb0d677b7
# ╟─d3bbc63a-0053-4812-94dc-61e446c8ee48
# ╟─1d9db32d-e7b5-4fa8-98b7-dc54d7179d4d
# ╟─0c48cf3d-d252-457c-a2c4-c52699441545
# ╟─7092b4c7-040b-469b-b6af-7cf060539c86
# ╟─383f07a3-fca6-458c-9412-dd3febd6e002
# ╟─7856b3a3-b7fb-476b-840b-fd2576f36e21
# ╟─7e8357b7-f471-4579-b817-4d74578d175e
# ╟─e8644415-5694-4775-8e93-062c2224122f
# ╟─c7fea193-fcb0-4777-944a-7a0c67491385
# ╟─a1d8f0f8-a871-459c-a7cc-216e543fd5af
# ╟─7522fb2b-ed2f-4376-8998-ceea7417b47f
# ╟─783c6626-a109-4203-b0d7-89b89cd00c35
# ╟─f67126f4-22ef-4f53-bfcb-49c9baa3d739
# ╟─e49c85c5-7c3d-4212-b435-0a7b3478e9ea
# ╟─e57c0c47-1e29-4fd9-b4e9-97ae81487d91
# ╟─e4a96bad-8ae9-4c9a-b49e-0122e22e1121
# ╟─1b6ac67a-7d66-4a85-b269-42a9855b69d5
# ╟─e3651bb5-3d8d-4368-95f4-c17f900a68d1
# ╟─19649292-4da6-47f8-8df6-7d39be4a3e9c
# ╟─4538fc7b-c622-4d17-8305-73556fc726da
# ╟─e5784a30-07b1-4782-8007-6f0eceba9818
# ╟─535089bc-0a97-4d9e-b4ac-e37f241bb01f
# ╟─d75c8269-ef70-48b4-b8aa-0fca2d7614cc
# ╟─dc8d3c44-7afd-4233-91e4-c5ae9448b6f3
# ╟─33d604d3-8f6c-42cc-9e5a-f2efadb853a4
# ╟─05780b18-b8a2-479d-9361-6f955450a8f9
# ╟─4c70a69a-0378-4df4-afd6-051ba60fe015
# ╟─955b0c97-6729-4c15-9287-804a757ed853
# ╟─b73072bd-6a67-435a-9e0c-daf6fceb4cd9
# ╟─d854dbcf-f00e-45e2-b4eb-bc39a2464a8e
# ╟─0eb60af8-e5ec-45c7-9ec7-5e6fbadc8538
# ╟─3110daa7-096f-4540-9ced-8d97036db9b7
# ╟─fba2a177-93d8-4e28-99d1-6fc34a8222c4
# ╟─86688652-33f2-44e7-ae43-0d4d166e2893
# ╟─c4fe042a-362a-43a7-b599-1052434a0580
# ╟─ee77994c-af70-4b66-b3c9-89f79f28a188
# ╟─be6c44d0-7385-4963-af24-a2f41024321b
# ╟─73200fe7-def9-41ac-92c6-378a2138284d
# ╟─cf386a0c-aa32-4328-a7c2-fa20141b5f9b
# ╟─9585d9db-bbd3-4483-9d91-049150bce1d0
# ╟─de213212-e527-4bd5-8d8d-0cbc4f7fbdd2
# ╟─bbb22037-c1a4-4e84-a4a9-624556d41381
# ╟─3e8330ce-1933-407f-a598-9dbb741163d5
# ╟─0a42a943-5767-444b-b0dd-78d086735fe5
# ╟─13e25dde-d9de-4cd4-a724-fde5c3f06592
# ╟─1d71f0b3-0233-4cb2-af04-5ea516aae2e2
# ╟─c155cd3a-28ac-4895-90f1-4e8d457c7555
# ╟─53ce5f41-00b9-4fe5-ae06-4ba1bf67f8ca
# ╟─73b3adf6-01fe-4d9a-b6fa-ea8190307a04
# ╟─b5502573-0511-4389-8809-79d5b1651516
# ╟─39348fce-b360-4f23-bf8c-8d2d28712328
# ╟─fe29c5c1-a6ca-4de5-ba74-83aa1ed5ddbb
# ╟─d49beeaa-1fcf-4f01-b355-0062b0cb636f
# ╟─8cf1edcb-2df9-423f-a775-87c1daa3a576
# ╟─f70cd513-8709-4481-95c8-796ee6405241
# ╟─33c46f9e-e582-4691-ac42-efeeec415ac9
# ╟─03b095af-d57e-41fe-8754-b4c0fdfa9a74
# ╟─af031fba-7035-4fa1-a9d4-c4d181d294f8
# ╟─a55e12ae-058e-4bac-8bb1-594e475ef3f1
