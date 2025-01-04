### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ c16597c4-9cf9-4a7d-966c-6b6b4aa4765b
begin
using PlutoUI,Images,TestImages, Wavelets, ImageFiltering, Plots, FFTW, DSP, LaTeXStrings

hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
theorem(text) = Markdown.MD(Markdown.Admonition("correct", "Theorem", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))	

lena = Float64.(testimage("fabio_gray_512"));
	
PlutoUI.TableOfContents(depth=4)
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""
# 9. Image Processing - Multi-Resolution Image Processing
[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ bdae42a3-8dbe-41ec-911a-89b087b26286
md"## 9.1 Motivation

There are different ways to motivate multi-resolution image processing. We start with a very general one coming from signal processing. We then use a slightly different viewpoint discussing image pyramids. Both will end up in a joint framework that is based on the wavelet transform.

"

# ╔═╡ 7fb00b76-16c3-48e3-a82f-ee5a21d6126c
note(md"Understanding the complete theory of wavelets is a lot more technical than for the Fourier series. We try to make the mathematics as comprehensive as possible.")

# ╔═╡ e42decda-7d72-4e63-8c89-1876fa66ac9b
md"
### 9.1.1 Time / Frequency Analysis

Let us have a look at the following signal:


"

# ╔═╡ c4739de9-b0a5-4107-bc04-e0d683ec679c
begin
	f1 = 5
	f2 = 10
	N = 1000
	t = range(0,1,length=N)
	s = vcat(zeros(N÷2),sin.(2*pi*t*f1), zeros(N÷2), sin.(2*pi*t*f2), zeros(N÷2))
	
	plot(s, lw=2, label=nothing, size=(700,410), xlabel = "time")
end

# ╔═╡ 0457f0ae-59c4-43a6-a795-738b976ff8b1
md"One might now be interested in the question: What frequency does this signal have?

In order to investigate this we can perform a Fourier transform:"

# ╔═╡ b7eeaeaf-74d2-43a1-b3a1-1c82b513079d
plot(abs.(rfft(s))[1:300], lw=2, label=nothing, size=(700,410), xlabel = "frequency")

# ╔═╡ e23fed14-1c3b-44b7-81b3-721ece0cd2d4
md"What we see is that the function contains two major frequencies.

The problem now is the following:
* the time signal does not contain information about the frequency.
* the frequency signal does not contain information about the time, at which the frequency appears.

"

# ╔═╡ e115cfb0-e02c-4975-87ee-2e8ee3a22575
md"##### Why should we care?

Two prominent examples: First is audio signal processing. When playing a song on an instrument, the tone (=base frequency) changes over time. In this case it is very important *when* a certain tone appeared.

When evaluating the heart function, one uses a [electrocardiogram](https://en.wikipedia.org/wiki/Electrocardiography), which is basically a time plot that shows the pumping action of the heart:

"

# ╔═╡ e9f5227e-16ce-4fdf-9776-22764b09a999
LocalResource("img/12leadECG.jpg")

# ╔═╡ a4ead200-3211-4f9f-b3ce-70f96984c062
md"In this case, again, one is interested in the heart frequency over time. This is also what you look at when using [fitness tracker](https://en.wikipedia.org/wiki/Activity_tracker)."

# ╔═╡ dfcd19fa-caf9-4819-8da7-501ee54a55ca
md"### 9.1.2 Short-Term Fourier Transform"

# ╔═╡ 2dce76f6-ceb3-4132-97a0-aa2263d5cc19
md"What we want is actually time-resolved frequency information. This can be accomplished by taking small intervals and applying a Fourier transform on the smaller intervals. This is named the [short-term Fourier transform](https://en.wikipedia.org/wiki/Short-time_Fourier_transform). For the continuous case it can be mathematically defined as

${\displaystyle \mathrm{STFT} ( s(t) )(\tau ,f) = S(\tau ,f)=\int _{-\infty }^{\infty }s(t)w(t-\tau )e^{-2\pi i ft}\,dt}.$

Here $w(t)$ is a window function that has two purposes:
1. Cutting out a small snippet of the time signal.
2. Letting the signal go smoothly to zero to avoid spectral leakage.
Usually a Hann window is used for that purpose.

The STFT returns not a 1D function but a 2D function with parameters $\tau$ and $f$. Thus, we have a time and frequency resolution now.
" 

# ╔═╡ 45e8211b-4f30-494e-af7b-0cc54866113e
md"#### 9.1.2.1 Time/Frequency Resolution

Although we have defined the STFT in a continuous fashion, it still has a discrete parameter that prevents us to have infinite time and frequency resolution. This is the width of the window $w$.

The wider $w$, the more frequencies can calculated but the time resolution decreases. Thus, one can trade of time and frequency resolution as is shown in the following time/frequency diagram:
"

# ╔═╡ 4172bbaa-a585-4a94-82d0-a8dd856cfc8d
LocalResource("img/STFT_-_windows.png")

# ╔═╡ 82bd2f53-f18e-40eb-ab25-03d3adb7d43d
md"#### 9.1.2.2 Spectrogram

The [spectrogram](https://en.wikipedia.org/wiki/Spectrogram) is defined to be the power spectrum of the STFT: 

$\operatorname {spectrogram} (s(t))(\tau ,\omega )\equiv |\text{STFT}(s(t))(\tau ,\omega )|^{2}$

It is used especially in audio signal processing. Here is the spectrogram of our original function:
"

# ╔═╡ 5d978b7c-e3fa-4775-9313-794010d7d1a8
begin
  a = spectrogram(s, length(s)÷16).power
  plot(
    heatmap(a[1:40,:], c=:viridis, 
			xlabel="time", ylabel="frequency", colorbar=nothing ),
    plot(s, lw=2, label=nothing, size=(700,500), xlabel = "time", xlim=(0,3500)), 
		layout=(2,1)
  )
	
end

# ╔═╡ 64fa6db3-1904-4dfe-8b7f-02853e3dee0b
md"One can clearly see that both time and frequency are resolved, i.e. we see that the one frequency is twice of the other frequency and where both frequencies occur on the time stripe.

The following shows a spectrogram of a violine play:"

# ╔═╡ dc36ffdb-0d20-4fbc-9cb5-51e58654ea36
LocalResource("img/Spectrogram_of_violin.png", :width=>500)

# ╔═╡ 7643b336-9f0d-41b2-b020-3e5215cfbd04
md"##### Whats wrong with the STFT?

If we look at the time/frequency diagram of the STFT we can see that we have an equidistant sampling of time and space. This is not very flexible. In particular, we would actually want to have
* high frequency resolution for the low frequencies. For them we do not need high time resolution.
* high time resolution for high frequencies. For them we do not need high frequency resolution.

"

# ╔═╡ a4cc701c-c5ca-46d8-8f44-dc803b74e855
md"Thus, what we actually want is a *multi-resolution transform*, i.e. we want to spend less samples for the lower frequencies and more samples on the high frequency parts. The transformation that accomplishes this is named the [wavelet transform](https://en.wikipedia.org/wiki/Wavelet_transform). The following shows how the wavelet transform samples the time/frequency space. "

# ╔═╡ d055363f-ccca-477a-b39b-13d268a627eb
LocalResource("img/STFT_and_WT.jpg")

# ╔═╡ 913bfc89-4174-4c37-a39a-7f7d75e9130d
md"We come to the proper definition of the wavelet transform later in this lecture."

# ╔═╡ 43edd2f5-a3cb-46af-8f02-645db056af23
md"#### 9.1.2.3 Uncertainty Principle

An important theorem regarding the ability to resolve both time and frequency is the [uncertainty principle](https://en.wikipedia.org/wiki/Uncertainty_principle):
"

# ╔═╡ de58b85a-caae-4868-884e-fb7db7a45f26
theorem(md"A signal cannot be band-limited in time and frequency. In particular it holds for any signal that
	
${\displaystyle \sigma _{t}\cdot \sigma _{f}\geq {\frac {1}{4\pi }}}$
	
where $\sigma_{t}$ and $\sigma_{f}$ are the standard deviations of the time and frequency estimates respectively (i.e. the width of the signals).")

# ╔═╡ 4c5618b3-582f-4f01-8cc0-ac5ca584e488
md"The link to the STFT is the width of the window function. The smaller we make it in time domain, the wider it gets in frequency domain."

# ╔═╡ 1a30a559-410c-499c-a6fd-167e83ff0cda
md"### 9.1.3 Human Pattern Recognition

We have another convincing argument for performing multi-resolution image processing. Let us look at the following two pictures. What can you see there?

"

# ╔═╡ 31155601-fdc8-415a-a100-9bf1b646501b
begin
  plot(
		heatmap(load("img/Abraham_Lincoln_head_on_shoulders_photo_portrait.jpg")
			,axis=nothing),
		heatmap(load("img/PinkertonLincolnMcClernand.jpg"),axis=nothing)
	  )
	
end

# ╔═╡ 61c20e22-d13c-4b44-b150-b0454c15079e
md"Of course both pictures contain the 16th president of the united states [Abraham Lincoln](https://de.wikipedia.org/wiki/Abraham_Lincoln). And it was basically possible to recognize this in a fraction of a second, although Lincoln has a different size in both pictures.

*How can we do that? Is our brain extremely powerful and can do STFTs in realtime?*

The answer is no, our brain is much smarter and performs multi-resolution pattern matching. So our brain is capable of
* first looking at the pictures identifying persons
* then focussing on the respective parts and the comparing them.
"

# ╔═╡ bbe77ac3-f557-4a29-a1d7-cf692a822109
md"## 9.2 Image Pyramids

Before we come to the wavelets we first take a look at so-called [image pyramids](https://en.wikipedia.org/wiki/Pyramid_(image_processing)), which are a predecessor to wavelets. 
"

# ╔═╡ 93f53bc7-e719-498f-99b8-e34f5f2ae1d0
md"### 9.2.1 Gaussian Pyramid

We start by looking at the image of Lena in different resolutions:
"

# ╔═╡ 1374d553-3be5-4538-ae27-3f81cc715a0f
begin
plot(
  heatmap(Gray.(lena)),
  heatmap(Gray.(imresize(lena,256,256))), 
  heatmap(Gray.(imresize(lena,128,128))),
  heatmap(Gray.(imresize(lena,64,64))),
  heatmap(Gray.(imresize(lena,32,32))),
  heatmap(Gray.(imresize(lena,16,16))),
  heatmap(Gray.(imresize(lena,8,8))),
  heatmap(Gray.(imresize(lena,4,4))),
  layout=(2,4), size=(800,365)
	)
end

# ╔═╡ 529568cb-274f-4b8f-8b3a-dd605e233512
md"We call this a Gaussian pyramid. 

Why? Because we can stack the images like this:"

# ╔═╡ b754d23a-7b97-42c4-a291-c9f6bf650c02
LocalResource("img/Image_pyramid.svg",:width=>300)

# ╔═╡ d651a3df-1b6f-45ce-9dc0-117be16d2757
md"When switching from one layer to the next we need to decrease the image size. This is done by two operations:
* smoothing filtering
* downsampling (typically a factor of two)
The first step is very crucial to avoid aliasing artifacts. For the moment you can think of a 2x2 Box filter that would do the job.
"

# ╔═╡ 4ec853ff-c781-43a0-902e-1ee572a0dbcd
md"Mathematically we can define the function 

$\text{downsample}: (I_N \rightarrow \Gamma) \rightarrow (I_{\frac{N}{2}} \rightarrow \Gamma)$ 

for the Box filter in the 1D case like this:

$\text{downsample}(s(i))(j) = g(j) = \sum_{k=1}^{2} s(2j + k) \quad \text{for} \quad j=1,\dots,\frac{N}{2}$

"

# ╔═╡ 1c47167f-bc44-4fae-a9b7-fc173777f9b1
md"##### What does the Gaussian Pyramid allow for?

The Gaussian Pyramid allows us to operate on an image on different scales. What basically happens is that we are low-pass filtering in each step, i.e. in contrast to the STFT we are not selecting sharp frequency bands but  larger portions of the frequency space of the signal.

The Gaussian Pyramid  allows us to perform image processing algorithms (like pattern recognition) on different scales.
"

# ╔═╡ a6ba3cff-943b-4b1d-a999-eb2de14ca96a
md"##### Size of Pyramid

One interesting question is how memory wasteful the storage of the pyramid is. Lets calculate this. 

**1D:**

Let the base signal be of size $N$. Then the pyramid contains the following amount of pixels:

$\left( N + \frac{N}{2} + \frac{N}{4} + \dots + 1  \right) = \sum_{i=0}^{\text{log}_2(N)} \frac{N}{2^i} = N \sum_{i=0}^{\text{log}_2(N)} \frac{1}{2^i} < N \sum_{i=0}^{\infty} \frac{1}{2^i} =  \frac{1}{1-\frac{1}{2}} N= 2N$

**2D:**

Let the base signal be of size $N=N_x \times N_y$. Then the pyramid contains the following amount of pixels:

$\left( N + \frac{N}{4} + \frac{N}{16} + \dots + 1  \right) = \sum_{i=0}^{\text{log}_4(N)} \frac{N}{4^i} = N \sum_{i=0}^{\text{log}_4(N)} \frac{1}{4^i} < N \sum_{i=0}^{\infty} \frac{1}{4^i} = \frac{1}{1-\frac{1}{4}} N= \frac{4}{3}N$
"

# ╔═╡ c7416938-8563-4c53-8ef0-b00dae70914c
md"Thus, in the case of 2D images, the increase in space is just 1/3 more than the original image."

# ╔═╡ 9d5e813b-3c55-4743-9abb-a82176ebad41
md"##### Time Complexity

Another question is how large the time complexity for creating the image pyramid is. Each downsampling requires ${\cal O}(\tilde{N})$ operations if $\tilde{N}$ is the size of the considered level. This is because we can use a small fixed-size kernel during the downsampling.

Consequently, the creation of a 2D image pyramid is ${\cal O}(N)$, which follows with the same calculation as for the space requirement.


"

# ╔═╡ 15173aea-dbf7-4534-ba07-dc2d3baf285e
note(md"At this point we already see a very important strength of multi-resolution processing algorithms. By dividing the resolution always by a factor of two we can obtain ${\cal O}(N)$ algorithms, which are much faster than general linear transformations that require ${\cal O}(N^2)$ operations.")

# ╔═╡ a1897a4a-d26e-4bf9-9fe8-054b8be1b9b0
md"### 9.2.2 Laplacian Pyramid

Now what is of course interesting is the difference between the downsampled image and the original image on a certain pyramid level. To this end we can define a function

$\text{upsample}: (I_\frac{N}{2} \rightarrow \Gamma) \rightarrow (I_{N} \rightarrow \Gamma)$ 

that takes the low resolution image and upsamples it using an appropriate interpolation technique (which does not matter at this point).

"

# ╔═╡ bd879134-910e-430a-b0c1-8a1f98b4cabf
md"The difference between the down- and upsampled image and the original image now can be expressed as 

$h(x,y) = f(x,y) - \text{upsample}(\text{downsample}(f(x,y))$

##### Why is that useful?

In the Gaussian pyramid we store $f(x,y)$ and $\text{downsample}(f(x,y))$ and $\text{downsample}(\text{downsample}(f(x,y))) \dots$

Now what if we drop $f(x,y)$ and instead store the difference image $h(x,y)$. Can we then restore $f(x,y)$ exactly from $\text{downsample}(f(x,y))$ and $h(x,y)$?

Yes, of course:

$f(x,y) = h(x,y) + \text{upsample}(\text{downsample}(f(x,y))$
"

# ╔═╡ ca69f861-5465-44cc-85b6-4a8f1100ba58
md"The idea of the [Laplacian pyradmid](http://persci.mit.edu/pub_pdfs/pyramid83.pdf) is now to only store the difference image on each level. Just on the last level we store the downsampled image (usually $2\times 2$). This looks like this:"

# ╔═╡ 2c34f920-69a8-43a9-871d-2222576f80ee
begin
	
function downupsample(f)
  N = size(f)
  fdown = imresize(f,N[1]÷2,N[2]÷2)
  diff = f - imresize(fdown,N[1],N[2])
  return fdown, diff
end

low1, h1 = downupsample(lena)
low2, h2 = downupsample(low1)
low3, h3 = downupsample(low2)
low4, h4 = downupsample(low3)
low5, h5 = downupsample(low4)
low6, h6 = downupsample(low5)
low7, h7 = downupsample(low6)
	
plot(
  heatmap(Gray.(h1.+0.5)),
  heatmap(Gray.(h2.+0.5)),
  heatmap(Gray.(h3.+0.5)),
  heatmap(Gray.(h4.+0.5)),
  heatmap(Gray.(h5.+0.5)),
  heatmap(Gray.(h6.+0.5)),
  heatmap(Gray.(h7.+0.5)),
  heatmap(Gray.(low7)), 
  layout=(2,4), size=(800,365)
	)
end

# ╔═╡ 1d19d1f9-9128-4a58-aced-bcee6f5b13b1
md"So what we store here is the edge information of the image. In fact, if you go back to the lecture on filtering in spatial domain you will see that we have effectively applied a *high-pass filter*."

# ╔═╡ 4cc1c8aa-4229-4716-8976-6b6d7677c4fa
md"##### Again, why is that useful?

First of all we have the same amount of data being stored as for the Gaussian pyramid. And we are able to perfectly recover each image on every level.

If you compare the Gaussian and the Laplacian pyramid you see that the later is a lot sparser, i.e. it contains in each level mostly zeros (or small values) and only at edges larger values. Consequently we can use this for image compression. To this end we store only the significant values (will be discussed again later). 


"

# ╔═╡ a28a5176-9786-4af6-afaf-4c731470d3c5
md"## 9.3 Wavelets

Wavelets have been developed in the 1980s and the 1990s and can be seen as a generalization of the STFT. Two important researchers having pushed wavelets and their theory are Ingrid Daubechies and Stéphane Mallat.
"

# ╔═╡ 63c739bb-6712-4662-b616-f1260ed4f61e
md"##### Why the term wavelet?

Wavelets basically means *small wave* and can be motivated even without wavelet theory by just looking at the STFT again:

${\displaystyle \mathrm{STFT} ( s(t) )(\tau ,f) = \int _{-\infty }^{\infty }s(t)w(t-\tau )e^{-2\pi i ft}\,dt}$

One can see that the complex exponential is multiplied with the window. Let us have a look at an exemplary $w(t-\tau )e^{-2\pi i ft}$ for a fixed frequency and four different shifts $\tau$:
"

# ╔═╡ 5b93995c-493f-4b10-8f4a-7ac93eff53ca
let 

  N = 500
  n = 100
  t = range(0,2π, length=N)
  hannWindow(M) = (1.0 .- cos.(2*π/(M-1)*(0:(M-1))))/(M-1)*M
  hannWindow(N,M) = vcat(hannWindow(M), zeros(N-M))
		
  plot(
	 plot(t, sin.(2*π*2*t),label="no window", c=:green),
	 plot(t, sin.(2*π*2*t).*hannWindow(N,n),label="τ1"),
	 plot(t, sin.(2*π*2*t).*circshift(hannWindow(N,n),80),label="τ1"),
	 plot(t, sin.(2*π*2*t).*circshift(hannWindow(N,n),159),label="τ2"),
	 plot(t, sin.(2*π*2*t).*circshift(hannWindow(N,n),238),label="τ3"),
	 layout=(5,1)
  )

end

# ╔═╡ cbca09fb-df4b-49bf-9569-6c52d7d21ec1
md"So you can see that
* the term wavelet (small wave) makes quite some sense.
* we can already see the shifting, which will be very important for the wavelets.
* the other important operation is the scaling, which is done for the STFT by changing the frequency as is shown in the next figure."

# ╔═╡ f3a7a9f4-4bb9-4689-b3d2-1cea153abff1
let 

  N = 500
  n = 25
  t = range(0,2π, length=N)
  hannWindow(M) = (1.0 .- cos.(2*π/(M-1)*(0:(M-1))))/(M-1)*M
  hannWindow(N,M) = vcat(hannWindow(M), zeros(N-M))
		
  plot(
	 plot(t, sin.(2*π*8*t),label="no window", c=:green),
	 plot(t, sin.(2*π*8*t).*circshift(hannWindow(N,n),0),label="τ1"),
	 plot(t, sin.(2*π*8*t).*circshift(hannWindow(N,n),80),label="τ1"),
	 plot(t, sin.(2*π*8*t).*circshift(hannWindow(N,n),159),label="τ2"),
	 plot(t, sin.(2*π*8*t).*circshift(hannWindow(N,n),239),label="τ3"),
	 layout=(5,1)
  )

end

# ╔═╡ 4feec265-94c7-4cc1-b8e6-f6fc4dc1b5d5
md"### 9.3.1 Continuous Wavelet Transform

So we have now all ingredient together to formally define the wavelet transform:
* we have the shifting with $\tau$.
* we have the frequency change, which can also be seen as a *scaling* or *dilation*.
* we have our small wave.

With that the continuous wavelet transform (CWT) can be written as

$W_\psi(s(t))(a,b) = \frac{1}{\sqrt{a}} \int_{-\infty}^\infty s(t)\overline{\psi\left(\frac{t-b}{a}\right)}dt\,.$

If you compare this to the STFT you can see that the only difference is that
* the basis function $w(t-\tau )e^{-2\pi i ft}$ has been replaced by the wavelet $\psi$. So this is mainly a generalization. 
*  $\tau$ has been renamed to $b$ (to use the common notation).
* instead of the frequency $f$ we consider the scaling $a$.
"

# ╔═╡ 5805a823-a88b-4d47-ba84-990a3669de61
md"#### 9.3.1.1 Mother Wavelet

We name $\psi$ the mother wavelet since it is used to generate an entire family of shifted and dilated wavelets:

$\psi_{a,b}(t) := \frac{1}{\sqrt{a}}\psi\left(\frac{t-b}{a}\right)$

Thus we can write the continuous wavelet transform as

$W_\psi(s(t))(a,b) = \frac{1}{\sqrt{a}} \int_{-\infty}^\infty s(t) \overline{\psi_{a,b}(t) } dt\,$
"

# ╔═╡ 4ce3bbdf-c166-45e4-918e-9984c6f59803
md"#### 9.3.1.2 Properties

Wavelets are usually taken from the function space $L^1(\mathbb{R})\cap L^2(\mathbb{R})$, i.e. it holds that

${\displaystyle \int _{-\infty }^{\infty }|\psi (t)|\,dt<\infty } \qquad \text{and} \qquad{\displaystyle \int _{-\infty }^{\infty }|\psi (t)|^{2}\,dt<\infty .}$

Additionally the mother wavelet needs to fulfill the *admissibility condition*:

$C_\psi = \int_{\mathbb{R}} \frac{\vert\hat{\psi}(\omega)\vert^2}{\vert \omega \vert} \text{d}\omega < \infty$

where $\hat{\psi}(f)$ is the Fourier transform of $\psi(t)$ and $C_\psi$ is named the admissible constant. 


"

# ╔═╡ 422b2a56-9123-4921-b909-7a8916567b14
md"
The admissibility condition directly implies that the Fourier transform of $\psi$ vanishes at frequency zero $\hat{\psi}(0) = 0$ so that

$\int _{-\infty }^{\infty }\psi(t)\,dt = 0$

This explains that
* Wavelets look like waves, i.e. they have the same amount of positive as negative parts.
* Wavelets have a high-pass/band-pass characteristic.
"

# ╔═╡ c1556b23-2ef0-44d2-a003-376d8dca52e6
md"#### 9.3.1.3 Inverse

The inverse of the continuous wavelet transform can be expressed as

$s(t)=\int_\mathbb{R} \int_\mathbb{R} W_\psi(s(t))(a,b) \psi_{a,b}(t)\,\text{d}b\,\frac{\text{d}a}{a^2}.$
"

# ╔═╡ 7251609e-9741-4dc6-bb63-97c7e38f3b44
note(md"The CWT is highly redundant, i.e. it maps a 1D signal into a 2D space. Thus the CWT is mainly used for signal analysis where such a redundancy can be ok/desired if fine-grained information about signal bands is required.
	
Since the CWT is mainly used for signal analysis, the synthesis (application of the inverse) is not that important.")

# ╔═╡ e6afa968-c606-4008-b99b-9aa647a69517
md"### 9.3.2 Wavelet Series

Since the CWT is so redundant it makes sense to reduce the space by sampling the parameters $a$ and $b.$ Usually this is done in a dyadic fashion ($a=2^{-m}$ and $b = n 2^{-m}$) yielding

$\psi_{m,n}(t) = 2^{-\frac{m}{2}}\psi\left(2^{-m} t - n\right) \quad \text{where} \quad m,n\in \mathbb{Z}.$

One can see that the translation is adapted to the scaling such that wider wavelets require less translations. 
"

# ╔═╡ 3b2b8c33-d488-4794-bd25-e04f969d264f
note(md"We from now on assume the wavelets to be real-valued which holds true in most practical use cases.")

# ╔═╡ e8ab992c-6e93-448b-9add-9419fbf88641
md"#### 9.3.2.1 Properties

The functions $\psi_{m,n}(t)$ defined in the previous way are an orthonormal basis of the Hilbert space $L^2(\mathbb{R})$. Thus the functions fulfill:

${\begin{aligned}\langle \psi _{{m,n}},\psi _{{m',n'}}\rangle &=\int _{{-\infty }}^{\infty }\psi _{{m,n}}(t) {\psi _{{m',n'}}(t)}\text{d}t =\delta _{{m,m'}}\delta _{{n,n'}}\end{aligned}}$

where ${\displaystyle \delta _{m,n}}$ is the Kronecker delta.

"

# ╔═╡ 7cf84a90-4fe1-424f-926b-a9498835056b
md"With this we can formulate the wavelet series:

$\begin{align} s(t) &=\sum _{m=-\infty }^{\infty } \sum _{n=-\infty }^{\infty }  \langle s ,\psi _{{m,n}}\rangle \psi _{m,n}(t) \\
&=\sum _{m=-\infty }^{\infty } \sum _{n=-\infty }^{\infty } T_{m,n}\psi _{m,n}(t) \\
\end{align}$

with the wavelet coefficients $T_{m,n}$ that can be calculated by

$T_{m,n} = \langle s ,\psi _{{m,n}}\rangle = \int_\mathbb{R} s(t) {\psi _{m,n}(t)} \text{d}t$
"

# ╔═╡ 2bd94dbd-bda6-4c8c-aaba-19a7949d8c61
note(md"Compare the wavelet series with the continuous Fourier transform. Both are defined on continuous functions on the real line, which is different than what we had for the Fourier transform. The wavelet series is now not redundant anymore.")

# ╔═╡ e2069793-a762-41bb-a060-478212b966b6
md"#### 9.3.2.2 Scaling Functions

What is missing until now is the connection to the image pyramids that allowed us to express images on different scales. This is accomplished by splitting the sum in the wavelet series into the wavelet part and a part that encodes the low-resolution part of the image.

To understand this we first need to introduced the *scaling functions* $\phi$. They are directly related to the wavelet $\psi$ and in fact  are derived from $\psi$ (or vice versa).
"

# ╔═╡ 32296750-291b-4fab-a854-253f26dfb115
note(md"Before we proceed: Think of $\phi$ being a low-pass filter (e.g. a box filter) whereas the wavelet $\psi$ is a high- or band-pass filter. We next need some technical details to formally construct the scaling functions.")

# ╔═╡ 0db1e121-0d39-4cd0-88c0-62be88dec20b
md" The scaling functions can be expressed as

$\phi_{m,n}(t) = 2^{-\frac{m}{2}}\phi\left(2^{-m} t - n\right) \quad \text{where} \quad m,n\in \mathbb{Z}$

where $\phi(t)$ is the base scaling function, sometimes also called the *father wavelet*. The scaling functions are orthogonal with respect to shifts but not with respect to scalings. The father wavelet is constructed in a way that it fullfills

$\int_\mathbb{R} \phi(t) \text{d}t = 1.$

Furthermore, the scaling functions are constructed in such a way that they are orthogonal to the wavelets on the same or a higher scale, i.e. we have

$\begin{align}
\langle \phi_{m,n}, \phi_{m,n'} \rangle &= \delta_{n,n'}  \quad \text{for}\quad m,n,n'\in \mathbb{Z}\\
\langle \phi_{m,n}, \psi_{m',n'} \rangle &= 0 \quad \text{for}\quad m\geq m' \;\text{and}\;m,n,n',n'\in \mathbb{Z}\\
\end{align}$ 
"

# ╔═╡ 45ffd3d0-28ce-4f19-8188-d8c5c25df69b
md"#### 9.3.2.3 Low-Pass Representation"

# ╔═╡ 45bc5b5c-e022-4053-aed1-efee98944e43
md"Using the scaling functions we can perform a low-pass filtering of a signal $s(t)$ by convolving $s(t)$ with $\phi_{m,k}(t)$ yielding the *approximation coefficients*

$S_{m,k} = \langle s ,\phi _{{m,k}}\rangle =\int_{\mathbb{R}} s(t) \phi_{m,k}(t) \text{d}t.$

Since $\phi_{m,k}(t)$ are orthogonal on the same scaling level, we can take the discrete signal $S_{m,k}$ and calculate a *continuous approximation* of $s(t)$ by

$s_m(t)=\sum_{k=-\infty}^{\infty } S_{m,k}\phi_{m,k}(t).$
"

# ╔═╡ 08b56c59-47b4-4315-88d6-395bd72ac412
note(md"Think about what happens if you let go $m\rightarrow -\infty$. Then $\phi_{m,k}$ will approach a Dirac distribution and in turn $s_m(t)$ will approach $s(t)$. When switching to the discrete setting, we can thus directly consider  $S_{m,n}$ to be our input signal where $m$ is the level defined by our pixel size. We stick with $s(t)$ for a moment but keep in mind that $S_{m,n}$ will be our discrete signal.")

# ╔═╡ fdf8029b-5e66-4586-bca1-eb0f3a0afe93
md"#### 9.3.2.4 Scaling and Wavelet Subspaces

Having defined the wavelet and the scaling functions we can look into their respective function spaces. We define

$\begin{align}
 V_m &= \text{span}(\phi_{m,n} : n\in \mathbb{Z}) \\
 W_m &= \text{span}(\psi_{m,n} : n\in \mathbb{Z}) \\
\end{align}$

to be the scaling function and the wavelet function space. From these definitions it is clear that

$\{0\}\subset\dots\subset V_{1}\subset V_{0}\subset V_{-1}\subset V_{-2}\subset\dots\subset L^2(\mathbb{R}),$

i.e. if we move one scale down from $V_m$ to $V_{m-1}$ we can express the same function plus those on the finer scale. It is also clear that 

$\lim_{m\rightarrow -\infty} V_{m} = L^2(\mathbb{R})$

since we are basically generating Dirac deltas that can be shifted around aribitrarily fine.
"

# ╔═╡ f2cde942-fbe4-4648-bb00-185f98870207
md"More interesting is now the relation to the wavelet spaces. One can show that $W_m$ is the orthogonal complement of $V_m$ inside the subspace $V_{m−1}$, i.e.

$V_m\oplus W_m=V_{m-1},$

where $\oplus$ is the direct sum of the function spaces. This followed from our assumption that the wavelets are orhtogonal to the scaling functions on the same level.

From this we now can derive:

$L^2(\mathbb{R}) = \underbrace{\underbrace{\underbrace{V_m \oplus W_m}_{V_{m-1}} \oplus W_{m-1}}_{V_{m-2}} \oplus W_{m-2}}_{V_{m-3}} \oplus \cdots$

which tells us that we can consider the band-limited function space $V_m$ and put all wavelet spaces $W_{m'}$ with $m'<m$ and then can express the entire $L^2(\mathbb{R})$. If we let $m\rightarrow\infty$ we derive

$L^2(\mathbb{R}) = \bigoplus_{m\in\mathbb{Z}} W_{m},$

which is our original assumption that the wavelets form an orthonormal basis of the Hilber space $L^2(\mathbb{R})$.


"

# ╔═╡ 810ba824-3e29-43ea-ac88-ac416067baa4
md"#### 9.3.2.5 Multi-Resolution Wavelet Series

What we have shown in the previous section implies that we can either express a signal $s\in L^2(\mathbb{R})$ either as

${s(t)=\sum _{m=-\infty }^{\infty } \sum _{n=-\infty }^{\infty } T_{m,n}\psi _{m,n}(t)}.$

or as

$s(t)= \sum_{n=-\infty}^{\infty } S_{m_0,n}\phi_{m_0,n}(t) + \sum _{m=-\infty }^{m_0 } \sum _{n=-\infty }^{\infty } T_{m,n}\psi _{m,n}(t).$


"

# ╔═╡ 4f38d2d7-782c-427c-88e6-379edd65195d
md"
The first part is the low resolution part $s_{m_0}(t)$ and the second part are the details at different levels. By defining

$d_m(t)=\sum_{n=-\infty}^{\infty } T_{m,k}\psi_{m,n}(t)$ 

we obtain

$s(t)= s_{m_0}(t) + \sum _{m=-\infty }^{m_0 } d_m(t)$

From that we can directly derive

$s_{m-1}(t)= s_{m}(t) + d_m(t)$

which tells us that if we add the signal detail at an arbitrary scale (index $m$) to the approximation at that scale we get the signal approximation at an increased resolution (i.e. at a smaller scale, index $m - 1$). This is called a multi-resolution representation.

"

# ╔═╡ fc31fed5-b326-4122-8ca8-59d4774c7775
note(md"We already have everything in place for performing a multi-resolution decomposition, which calculates all difference images $d_m(t)$ until the pixel resolution and additionally needs to store one low-resolution image $s_{m'}(t)$.

One could of course calculate  $s_{m'}(t)$ and all the $d_m(t)$ directly by calculating the coefficients $T_{m,n}$ and $S_{m',n'}$ via the inner products. However, this is not efficient and we therefore derive in the next two subsections  a more efficient ways to do this.
")

# ╔═╡ b526cb00-1b92-4243-9d18-c9f592f48b5d
md"#### 9.3.2.6 Two-Scale Relation

To derive the fast wavelet transform we need the two scale relations that can be derived as follows. Lets have a look at the inner products of the wavelet and the scaling functions with the scaling functions one level lower:

$\begin{align}
 c_k = \langle \phi_{0,0}, \phi_{-1,k} \rangle = \int_\mathbb{R} \phi_{0,0}(t) \phi_{-1,k}(t) \,\text{d}t = \sqrt{2} \int_\mathbb{R} \phi(t) \phi(2t - k) \,\text{d}t \\
 b_k = \langle \psi_{0,0}, \phi_{-1,k} \rangle = \int_\mathbb{R} \psi_{0,0}(t) \phi_{-1,k}(t) \,\text{d}t = \sqrt{2} \int_\mathbb{R} \psi(t) \phi(2t - k) \,\text{d}t
\end{align}$

 $c_k$ and $b_k$ are named the scaling and wavelet coefficients, respectively. Since $\phi,\psi \in V_{-1}$ we have 

$\begin{align}
 \phi(t) = \sum_{k=-\infty}^{\infty} \langle \phi_{0,0}, \phi_{-1,k} \rangle \phi_{-1,k}(t) =  \sum_{k=-\infty}^\infty \sqrt{2} \,c_k\, \phi(2t - k)  \\
 \psi(t) = \sum_{k=-\infty}^{\infty} \langle \psi_{0,0}, \phi_{-1,k} \rangle \phi_{-1,k}(t) =  \sum_{k=-\infty}^\infty \sqrt{2} \,b_k\, \phi(2t - k)  \\
\end{align}$
"

# ╔═╡ 4b1750dc-6f0d-40b2-8962-66bb635afa7d
md"These are called the two-scale relations. They imply  that we can break down $\phi(t)$ into several parts that can be expressed as a scaled and shifted versions of $\phi(t)$ again. The same holds true for the wavelets $\psi(t).$"

# ╔═╡ 152ef7c6-f966-4d15-a68b-3e70b99864a1
note(md"In practice both series have only few non-zero coefficients, i.e.  one designs the wavelet in that way.")

# ╔═╡ b019228d-1056-43d8-a2c3-7965d578b48f
md"Finally, if we now consider our dyadic wavelets $\psi_{m,n}$ and the dyadic scaling functions $\psi_{m,n}$ we can exploit the two-scale relations to end up at

$\begin{align}
  \psi_{m+1,n}(t) &= \sum_{k=-\infty}^{\infty} b_k \,\phi_{m,2n+k}(t) \\
  \phi_{m+1,n}(t) &= \sum_{k=-\infty}^{\infty} c_k \,\phi_{m,2n+k}(t) 
\end{align}$


"

# ╔═╡ 5028541e-5411-45ce-8b86-5d32311c8951
md"We will need these relations later."

# ╔═╡ 4078fc42-f401-44c5-8933-13fb656a24ba
md"#### 9.3.2.7 Connection Between Coefficients

The coefficients $c_k$ and $b_k$ are directly connected. In practice this means that one defines the scaling function $\phi$ by defining $c_k$ and from that directly derives $b_k$, which defines the wavelet $\psi.$ This is because we required the wavelets to be the orthogonal complement to the scaling functions. 

The relation is given  by

$b_k = (-1)^k c_{1-k} \qquad k \in \mathbb{Z}.$

To show that these coefficents lead to orthogonal wavelets we calculate
"

# ╔═╡ 8927a56d-528f-49ba-8184-3af4f3d73905
md"
$\begin{align}
\langle \phi_{0,0}, \psi_{0,n}\rangle & = \int_\mathbb{R} \phi_{0,0}(t) \psi_{0,n}(t) \text{d}t \\
& = \sum_{k=-\infty}^{\infty} \sum_{l=-\infty}^{\infty} c_k b_l \underbrace{ \int_\mathbb{R} \phi_{-1,k}(t) \phi_{-1,2n+l}(t) \text{d}t}_{\delta_{k,2n+l}} \\
& = \sum_{k=-\infty}^{\infty}  c_k b_{k-2n}  \\
& = \sum_{k=-\infty}^{\infty}  c_k (-1)^{k-2n} c_{1-k+2n} \\
& = \sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n} \\
& = \frac{1}{2}\left(\sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n} + \sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n}\right) \\
& = \frac{1}{2}\left(\sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n} + \sum_{\kappa=-\infty}^{\infty}  c_{1-\kappa+2n} (-1)^{1-\kappa+2n} c_{\kappa}\right) \\
& = \frac{1}{2}\left(\sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n} + \sum_{\kappa=-\infty}^{\infty} (-1) c_{1-\kappa+2n} (-1)^{\kappa} c_{\kappa}\right) \\
& = \frac{1}{2}\sum_{k=-\infty}^{\infty}  c_k (-1)^{k} c_{1-k+2n} - c_{1-k+2n} (-1)^{k} c_{k} = 0 \\
\end{align}$
"

# ╔═╡ 3c0fb676-e7c2-4eba-a3bf-4673217d6a6a
md"In addition we can also derive some constraints on the coefficients $c_k$:

$\begin{align}
1 &= \int_\mathbb{R} \phi(t) \,\text{d}t \\
  &= \int_\mathbb{R} \sum_{k=-\infty}^\infty\sqrt{2} c_k  \phi(2t-k) \,\text{d}t \\
  &= \sum_{k=-\infty}^\infty\sqrt{2} c_k \underbrace{ \int_\mathbb{R} \phi(2t-k) \,\text{d}t }_{\frac{1}{2}}
\end{align}$

Thus we have

$\sum_{k=-\infty}^\infty c_k = \sqrt{2}.$

"

# ╔═╡ a6d42a16-cf7e-4101-bb67-c67b08d046a8
md"
Furthermore we have

$\begin{align}
\langle \phi_{0,0}, \phi_{0,n} \rangle & = \int_\mathbb{R} \phi_{0,0}(t) \phi_{0,n}(t) \text{d}t \\
& = \sum_{k=-\infty}^{\infty} \sum_{l=-\infty}^{\infty} c_k c_l \underbrace{ \int_\mathbb{R} \phi_{-1,k}(t) \phi_{-1,2n+l}(t) \text{d}t}_{\delta_{k,2n+l}} \\
& = \sum_{k=-\infty}^{\infty}  c_k c_{k-2n} 
\end{align}$

Since $\langle \phi_{0,0}, \phi_{0,n}\rangle =  \delta_{0,n}$ we have

$\sum_{k=-\infty}^{\infty}  c_k c_{k-2n} = \delta_{0,n}$
"


# ╔═╡ 4a1c5902-9557-43ea-b74f-0ab0f1bb3666
md"#### 9.3.2.8 Example: The Haar Wavelet

Lets have a look at the Haar wavelet, which is the most basic wavelet one can think of. It is defined as

$\psi(t) = \begin{cases}
1 & \text{if}\quad 0\leq t <\frac{1}{2} \\
-1 & \text{if}\quad \frac{1}{2}\leq t < 1 \\
0 & \text{else}
\end{cases}$

and has the scaling function 

$\phi(t) = \begin{cases}
1 & \text{if}\quad 0\leq t <1 \\
0 & \text{else}
\end{cases}$

Both functions are shown next:
"

# ╔═╡ 2b7166ec-8908-464d-8a38-c4a31d8835c9
begin
  Haar(t) = t<0 || t>1 ? 0.0 : (t<0.5 ? 1 : -1)
  HaarScaling(t) = t<0 || t>1 ? 0.0 : 1
  tt = range(-1,2, length=200)
  plot(
    plot(tt, HaarScaling.(tt),xlabel="t", ylabel=L"\phi", lw=2, c=1, label=nothing, ylim=(-1,1)),
    plot(tt, Haar.(tt),xlabel="t", ylabel=L"\psi", lw=2, c=2, label=nothing), size=(650,340))
end

# ╔═╡ ee9eb19b-b0de-4e83-8851-d3b7defa4576
md"The only non-zero coefficients are $c_0=\frac{1}{\sqrt{2}}$ and $c_1=\frac{1}{\sqrt{2}}$ ($b_0 =\frac{1}{\sqrt{2}}$, $b_1 =-\frac{1}{\sqrt{2}}$). I.e.  the two-scale relations can be expressed as:

$\phi(t) = \phi(2t ) + \phi(2t - 1) = \sqrt{2} (c_0 \phi(2t ) + c_1\phi(2t - 1))$

and

$\psi(t) = \phi(2t ) - \phi(2t - 1) = \sqrt{2} (b_0 \phi(2t ) + b_1\phi(2t - 1)).$
"

# ╔═╡ 57aab465-2225-4f7b-be1b-599bda427ba8
md"One can see that $\phi$ can be constructed by adding two shifted and scaled versions of $\phi$. To construct $\psi$ we take one positive scaled $\phi$ and one negative shifted and scaled $\phi$."

# ╔═╡ 3711f6d7-a418-4563-94a5-dd754e438247
md"The following  shows how the Haar basis functions and the corresponding scaling functions look like on three different scales:"

# ╔═╡ d68d0b72-d7a5-4d50-ad27-4b8e8d19ada1
LocalResource("img/HaarBasis.png", :width=>700)

# ╔═╡ 533ba422-c467-4ed6-854c-2989a1f7631e
md"#### 9.3.2.9 Fast Wavelet Transform
The goal is now to get from the signal $S_{m,n}$ to the coefficients $T_{m+1,n}$ and $S_{m+1,n}$ and vice versa. If we can do that, it is possible to  decompose $S_{m,n}$ step by step into finer and finer details. 
"

# ╔═╡ 578a4f0d-3626-459b-8dc7-e7069b875f37
md"##### Level Up

To go from the signal to the coefficients, we want to calculate the coefficients $S_{m+1,n}$ and $T_{m+1,n}$ from $S_{m,n}$. We have

$\begin{align}
S_{m+1,n} &=\int_{-\infty}^{\infty } s(t) \phi_{m+1,n}(t) \,\text{d}t \\
  &=\int_{-\infty}^{\infty } s(t) \left(\sum_{k=-\infty}^{\infty} c_k \,\phi_{m,2n+k}(t)\right) \,\text{d}t \\
    &= \sum_{k=-\infty}^{\infty} c_k \left(\int_{-\infty}^{\infty } s(t)  \,\phi_{m,2n+k}(t)  \,\text{d}t  \right)\\
   &= \sum_{k=-\infty}^{\infty} c_k S_{m,2n+k} \\
   &= \sum_{k=-\infty}^{\infty} c_{k-2n} S_{m,k}.\\
\end{align}$

In the last step we have applied an index shift. In the same way we can also derive

$\begin{align}
T_{m+1,n} &= \sum_{k=-\infty}^{\infty} b_{k-2n} S_{m,k}.
\end{align}$

"

# ╔═╡ 60f54380-64fb-4c92-9a42-4395417464cc
md"##### Level Down
Next task is to get from $S_{m,n}$ and $T_{m,n}$ to $S_{m-1,n}$. We already know that $s_{m-1}(t)= s_{m}(t) + d_m(t)$, which can be enrolled to

$\begin{align}
s_{m-1}(t) &= \sum_{n=-\infty}^{\infty } S_{m,n}\phi_{m,n}(t) + \sum_{n=-\infty}^{\infty } T_{m,n}\psi_{m,n}(t) \\
  &= \sum_{n=-\infty}^{\infty } S_{m,n} \sum_{k=-\infty}^{\infty} c_k \,\phi_{m-1,2n+k}(t) + \sum_{n=-\infty}^{\infty } T_{m,n} \sum_{k=-\infty}^{\infty} b_k \,\phi_{m-1,2n+k}(t) \\
 &= \sum_{n=-\infty}^{\infty } S_{m,n} \sum_{k=-\infty}^{\infty} c_{k-2n} \,\phi_{m-1,k}(t) + \sum_{n=-\infty}^{\infty } T_{m,n} \sum_{k=-\infty}^{\infty} b_{k-2n} \,\phi_{m-1,k}(t) \\
 &= \sum_{k=-\infty}^{\infty } \phi_{m-1,k}(t) \left( \sum_{n=-\infty}^{\infty}  c_{k-2n} S_{m,n} + \sum_{n=-\infty}^{\infty}  b_{k-2n} T_{m,n}  \right) \\
\end{align}$

"

# ╔═╡ b4804a6c-772b-4309-bbcc-24827263ccdc
md"On the other hand we can also express $s_{m-1}(t)$ by just the basis functions $\phi_{m-1,k}(t)$:

$s_{m-1}(t) = \sum_{k=-\infty}^{\infty } S_{m-1,k} \phi_{m-1,k}(t).$"

# ╔═╡ 8da7cbd0-7a3f-4a6e-8e6a-71ca386df76c
md"When equating both expressions we can see that $S_{m-1,k}$ needs to be the same as the term in brackets. After relabeling $k$ as $n$ we obtain:

$\begin{align}
S_{m-1,n} &= \sum_{k=-\infty}^{\infty} c_{n-2k} S_{m,k} + \sum_{k=-\infty}^{\infty} b_{n-2k} T_{m,k}\\
\end{align}$

This now allows us to calculate $S_{m-1,n}$ from $S_{m,n}$ and $T_{m,n}$.
"

# ╔═╡ 6860b5d8-78df-45f8-82dd-2691443d7b17
note(md"An interesting fact is that we can calculate the coefficients without direct knowledge of the wavelet  $\psi$ and the scaling function $\phi$. In practice, for the discrete wavelet transform, one thus just needs the coefficients $c_k$ and $b_k$.")

# ╔═╡ 039f5036-b6f0-46dd-9735-c0ef1bbe2650
md"### 9.3.3 Discrete Wavelet Transform

In the last section we were discussing the wavelet series but we had already the discrete setting in mind. What is important to note is that we stepped over the coefficients $c_k$ and $b_k$ with a spacing of two indices, which means that the number of non-zero coefficients halves if we go one step up and consider that we started with a finite length input signal. 

This brings us then to the [discrete wavelet transform (DWT)](https://en.wikipedia.org/wiki/Discrete_wavelet_transform). Since we are bisecting the signal in each step and generate from $S_{m,n}$ the signals $S_{m+1,n}$ and $T_{m+1,n}$ we can update the original signal *inplace* which also means that the DWT has zero redundancy. This is graphically shown in the next picture:
"

# ╔═╡ df5a1f92-c1c3-4437-955f-2e323a35932b
LocalResource("img/DWTTree.png")

# ╔═╡ 585d9685-88d7-4a02-8ac8-d60e8b40e0ec
note(md"We left out the formal definition of the DWT since this lecture contains enough mathematical details in the previous sections to understand the basic concept.")

# ╔═╡ 235b1120-dcaf-44a9-9130-281fe5fac74a
note(md"One does not necessary perform the full DFT but it is also possible to stop at one level. This is even necessary when considering signals that are not powers of two. See what happens if we apply the DWT to an odd signal.")

# ╔═╡ 2afc2384-be8b-41f6-a2fa-858bcc615474
dwt([1.0,2,3,4,5,6,7,8,9], wavelet(WT.db1))

# ╔═╡ 0089c457-42a2-4080-97b4-be8d8ca1ff2d
maxtransformlevels([1.0,2,3,4,5,6,7,8,9])

# ╔═╡ cc3852c0-4982-4d05-b467-cf28fd0b5c41
md"#### 9.3.3.1 Time Complexity

The time complexity for performing the DWT is ${\cal O}(N)$, which is very fast when taking into account that the DWT matrix has ${\cal O}(N^2)$ entries. This is even faster than the FFT which had a time complexity of ${\cal O}(N \log N)$.

The reason that the DWT is even faster is that the FFT, which also breaks the signal in halves, operates on both signal halves. The DWT, on the other hand, just operates on one of the halves and keeps the second halve untouched when going one level up.
"

# ╔═╡ 727b5b19-52e3-44ce-8661-a48222619910
md"### 9.3.4 Wavelet Types

Until now we  kept the wavelet function and its scaling function generic, which means that various wavelets can be used in practice. Here is a small overview:
"

# ╔═╡ 76966f7e-840a-4434-952b-f179d72c57a6
LocalResource("img/wavelet_families.png",:width=>700)

# ╔═╡ 21978ad7-a56c-4959-b491-63d187b5f927
md"You can also visit the [wavelet browser](http://wavelets.pybytes.com/).
"

# ╔═╡ 14b4be96-bbad-420e-be13-1b55ea5618d8
md"When choosing a different wavelet the resulting coefficients $T_{m,n}$ and $S_{m,n}$ will also be different. This allows  to tailor the wavelet to a specific signal class. In practice the differences are, however, not too large and usually it is a good choice to select one of the [Daubechies wavelets](https://en.wikipedia.org/wiki/Daubechies_wavelet)."

# ╔═╡ 37c5ef80-2f0a-40f2-a687-b239115ddc0f
md"### 9.3.5 Multi-Dimensional Wavelet Transform

We of course want to apply the DWT to images and therefore need to extend everything to multiple dimensions. This is done using a tensor product approach. In 2D we then have the following wavelet and wavelet scaling functions:

* 2D scaling function: $\phi(t_1,t_2) = \phi(t_1) \phi(t_2)$
* 2D horizontal wavelet: $\psi^\text{h}(t_1,t_2) = \phi(t_1) \psi(t_2)$
* 2D vertical wavelet: $\psi^\text{v}(t_1,t_2) = \psi(t_1) \phi(t_2)$
* 2D diagonal wavelet: $\psi^\text{d}(t_1,t_2) = \psi(t_1) \psi(t_2)$

We thus need to break a 2D image into four parts and then successively apply one level of the transformation. This is illustrated in the following picture:
"

# ╔═╡ 87f7886b-3fee-4440-b5aa-3262ba0a0c11
LocalResource("img/2DDWT.png",:width=>400)

# ╔═╡ 82b8f813-10f5-4bcb-99e3-a534459402b0
md"Lets now go through the levels for Fabio:"

# ╔═╡ 644f6302-6609-4ec2-9250-333410738141
let
A = testimage("fabio_gray_512", nowarn=true);
B = convert.(Float64, A);
C = dwt(B, wavelet(WT.db7), 0);
plot(heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 0) ,dims=1)).+0.01)), 
              title="Level 0", c=:viridis),
	 heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 1) ,dims=1)).+0.01)), 
              title="Level 1", c=:viridis),
	 heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 2) ,dims=1)).+0.01)), 
              title="Level 2", c=:viridis),
	 heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 3) ,dims=1)).+0.01)), 
              title="Level 3", c=:viridis),
	 heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 4) ,dims=1)).+0.01)), 
              title="Level 4", c=:viridis),
	 heatmap((log.(abs.(reverse( dwt(B, wavelet(WT.db7), 5) ,dims=1)).+0.01)), 
              title="Level 5", c=:viridis),
     size=(800,1000), layout=(3,2))
end

# ╔═╡ 9eda219f-27f4-4ba5-8acf-b2b5a0ab8415
md"## 9.4 Applications

The wavelet transform has several applications in signal and image processing and is overlapping with what can be done with usual Fourier space filtering. Here we sketch some of the applications.
"

# ╔═╡ 7e7ad2e9-6c5c-4ac6-b228-f942f221f559
md"### 9.4.1 Image Compression

The first application that we consider is image compression. Let us have a look at Lena and its discrete wavelet transform:
"

# ╔═╡ 15db15ab-8e3a-473f-a1c6-457bb41d792d
let
A = testimage("fabio_gray_512", nowarn=true);
B = convert.(Float64, A);
C = dwt(B, wavelet(WT.db7));
CThresh = deepcopy(C)
threshold!(CThresh, Wavelets.Threshold.SoftTH(), 0.04)
numZeros = sum(CThresh.== 0)
amountData = round(Int,(1 - numZeros/length(CThresh))*100)
BThresh = idwt(CThresh, wavelet(WT.db7));
plot(heatmap(reverse(B,dims=1), title="Image Space", c=:viridis),
     heatmap((log.(abs.(reverse(C,dims=1)).+0.01)), title="DWT Space", c=:viridis),
     size=(800,320))
end

# ╔═╡ 44be4109-442f-4fb9-b360-34043ab8add8
md"##### Observation

* The DWT coefficients are mostly zero. Only at edges higher coefficients can be observed.
* The DWT is, for natural images, thus a sparsifying transform.

"

# ╔═╡ bbe1ae25-9d71-4501-954f-41c9d6f51998
md"Based on this observation one can derive an algorithm where only a fraction of the information is stored. To this end one
* calculates the DWT.
* applies a threshold setting a large fraction of coefficients to zero.
* store the resulting sparse matrix using an efficient data format.
In order to load compressed data one can then
* load the sparse matrix.
* apply an inverse DWT.

The following shows a data reduction by a factor of 10, which is a very good value for 2D image compression. One can hardly see any difference to the original image.
"

# ╔═╡ 19931f1e-8be7-4116-9f44-ee3ea13f9b83
let
A = testimage("fabio_gray_512", nowarn=true);
B = convert.(Float64, A);
C = dwt(B, wavelet(WT.db7));
CThresh = deepcopy(C)
threshold!(CThresh, Wavelets.Threshold.SoftTH(), 0.04)
numZeros = sum(CThresh.== 0)
amountData = round(Int,(1 - numZeros/length(CThresh))*100)
BThresh = idwt(CThresh, wavelet(WT.db7));
plot(heatmap(reverse(BThresh,dims=1), title="Image Space $(amountData)%", c=:viridis),
     heatmap((log.(abs.(reverse(CThresh,dims=1)).+0.01)), title="DWT Space $(amountData)%", c=:viridis),
     size=(800,320))
end

# ╔═╡ cb3d296a-590d-447b-9578-b14c3e2661ae
md"
Wavelet based image compression has been implemented in the [JPEG_2000](https://en.wikipedia.org/wiki/JPEG_2000) picture standard that achieves higher compression rates than JPEG.
"

# ╔═╡ c0c754e1-a599-496f-8066-3d12d72083c9
md"### 9.4.2 Noise Reduction

Another important application of the wavelet transform is noise reduction. Similar to the Fourier transform, the noise distributes equally into all coefficients:
"

# ╔═╡ 7644847b-c850-47c1-8662-31fba0130635
let
B = randn(128,128)
C = dwt(B, wavelet(WT.db7));

plot(heatmap(reverse(B,dims=1), title="Image Space", c=:viridis),
     heatmap(reverse(C,dims=1), title="DWT Space", c=:viridis),
     size=(800,320))
end

# ╔═╡ 88c967db-e214-4cb1-a719-8d4dc45464ba
md"The signal usually goes down going from one to the next level. Thus, we can threshold the noise more effectively in wavelet space than in image space. 

The following shows a denoise example:"

# ╔═╡ 1ee65ad1-9f5d-418d-aa1c-d3ea4e923257
let
n = 2^11;
x0 = testfunction(n,"Doppler")
x = x0 + 0.05*randn(n)
y = denoise(x,TI=true)

plot(
  plot(x0,lw=1.5, label=nothing, title="original"),
  plot(x,lw=1.5, label=nothing, title="noisy"),
  plot(y,lw=1.5, label=nothing, title="denoised"),
  layout=(3,1)
)
end

# ╔═╡ 596f6481-1324-4e0d-afe7-f2868f2bde31
md"Here is another example, where the noise is applied to an image."

# ╔═╡ cb8fdf58-24c5-41b9-b4f4-04e138684297
let
  A = testimage("fabio_gray_512");
  B = convert.(Float64, A);
  noise = 0.2*randn(size(B))
  BNoise = B + noise
  BDenoise = denoise(BNoise,TI=true)

  plot(heatmap(Gray.(B), title="original", c=:viridis, colorbar=nothing),
	   heatmap(Gray.(BNoise), title="noisy", c=:viridis, colorbar=nothing),
     heatmap(Gray.(BDenoise), title="denoised", c=:viridis, colorbar=nothing),
     size=(800,255), layout=(1,3))
end

# ╔═╡ 6675666b-4d43-4aef-bf2c-168c9869f80a
md"Wavelets also allow for removing local noise, what would not be possible with Fourier-based methods:"

# ╔═╡ 1edda966-72e7-43c2-9cb6-004decabfc1f
LocalResource("img/LocalDenoising.png")

# ╔═╡ 62c9b84d-2fd3-48b6-8f91-99539c6e2e2a
md"### 9.4.2 Further Applications

The wavelet transform has various additional applications. For example:
* It can be used for *feature extraction*. For instance fingerprint recognition techniques can be based on the wavelet transform.
* In time data analysis (speach recognition, ECG processing),  the wavelet transform can be used to match patterns in the wavelet domain.
* In addition the DWT is often used as a *sparsifying transform*. This means that a dense signal is sparsified and can be represented by fewer coefficients. This principle is often used in the field of [compressed sensing](https://en.wikipedia.org/wiki/Compressed_sensing), which has the goal of reconstructing high resolution images from only few measurements (i.e. less samples than the number of image pixels).
"

# ╔═╡ 23525253-82cf-467f-9bdf-59b7b07c45b2
md"## 9.5 Deep Neural Networks

The field of machine learning, which is nowadays commonly using deep neural networks is heavily influenced by multi-resolution analysis. Let us have a look at a UNet:

"

# ╔═╡ c0583f12-2cb7-4429-aa75-3291e5e4c18b
LocalResource("img/unet.png",:width=>700)

# ╔═╡ 17ed83aa-5bba-484b-bae6-2543f63df46f
md"What you can see here is that the input image is forwarded layer-by-layer and each layer performs a convolution and/or up- and downsampling operations. In this way a deep neural network can learn very complex transformations and in-fact perform a (custom) multi-resolution analysis.

But note that deep neural networks are much more than just a multi-resolution analysis. The kernels (which can be compared to wavelets) are not static within a neural network but they are fitted to the data within the learning process. This means a neural network is much more flexible (pro) but needs data (con) for training. But despite these differences it is still remarkable that both research areas share a common concept."

# ╔═╡ c6aa6ae2-2b64-4bfe-98bd-07bae4fa068e
md"## 9.6 Wrapup

In this lecture we introduced multi-resolution image processing as a powerful tool for various common image processing tasks.
* We found that human pattern recognition works in a multi-resolution fashion.
* We used the wavelet transform as the formal tool to specify multi-resolution image processing. Image pyramids were used as a simple motivating example.
* Wavelet transforms can be applied to continuous and discrete signals. For 2D/3D signals a tensor approach is applied.
* Wavelets have various important applications and can be for example used for
  * image compression
  * noise reduction
  * sparse sampling
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DSP = "717857b8-e6f2-59f4-9121-6e50c889abd2"
FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
ImageFiltering = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
TestImages = "5e47fb64-e119-507b-a336-dd2b206d9990"
Wavelets = "29a6e085-ba6d-5f35-a997-948ac2efa89a"

[compat]
DSP = "~0.7.9"
FFTW = "~1.7.2"
ImageFiltering = "~0.7.8"
Images = "~0.26.0"
LaTeXStrings = "~1.3.1"
Plots = "~1.39.0"
PlutoUI = "~0.7.54"
TestImages = "~1.8.0"
Wavelets = "~0.10.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "843f00c1f501ae59a18ce2a3c07ed34e1a03ab72"

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
git-tree-sha1 = "50c3c56a52972d78e8be9fd135bfb91c9574c140"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.1.1"
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
git-tree-sha1 = "d5140b60b87473df18cf4fe66382b7c3596df047"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.17.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = "CUDSS"
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
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
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
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
git-tree-sha1 = "cc5231d52eb1771251fbd37171dbc408bcc8a1b6"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.4+0"

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
git-tree-sha1 = "2dd20384bf8c6d411b5c7370865b1e9b26cb2ea3"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.6"
weakdeps = ["HTTP"]

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

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
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

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
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

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
git-tree-sha1 = "8a3271d8309285f4db73b4f662b1b290c715e85e"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.21"

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

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "OrderedCollections", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "adc25dbd4d13f148f3256b6d4743fe7e63a71c4a"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.0.12"

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

[[deps.Wavelets]]
deps = ["DSP", "FFTW", "LinearAlgebra", "Reexport", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "f514f9b16f6a15552c6aad7b03afc7b9a8478ef4"
uuid = "29a6e085-ba6d-5f35-a997-948ac2efa89a"
version = "0.10.0"

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
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "a2fccc6559132927d4c5dc183e3e01048c6dcbd6"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.5+0"

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
# ╟─7fb00b76-16c3-48e3-a82f-ee5a21d6126c
# ╟─e42decda-7d72-4e63-8c89-1876fa66ac9b
# ╟─c4739de9-b0a5-4107-bc04-e0d683ec679c
# ╟─0457f0ae-59c4-43a6-a795-738b976ff8b1
# ╟─b7eeaeaf-74d2-43a1-b3a1-1c82b513079d
# ╟─e23fed14-1c3b-44b7-81b3-721ece0cd2d4
# ╟─e115cfb0-e02c-4975-87ee-2e8ee3a22575
# ╟─e9f5227e-16ce-4fdf-9776-22764b09a999
# ╟─a4ead200-3211-4f9f-b3ce-70f96984c062
# ╟─dfcd19fa-caf9-4819-8da7-501ee54a55ca
# ╟─2dce76f6-ceb3-4132-97a0-aa2263d5cc19
# ╟─45e8211b-4f30-494e-af7b-0cc54866113e
# ╟─4172bbaa-a585-4a94-82d0-a8dd856cfc8d
# ╟─82bd2f53-f18e-40eb-ab25-03d3adb7d43d
# ╟─5d978b7c-e3fa-4775-9313-794010d7d1a8
# ╟─64fa6db3-1904-4dfe-8b7f-02853e3dee0b
# ╟─dc36ffdb-0d20-4fbc-9cb5-51e58654ea36
# ╟─7643b336-9f0d-41b2-b020-3e5215cfbd04
# ╟─a4cc701c-c5ca-46d8-8f44-dc803b74e855
# ╟─d055363f-ccca-477a-b39b-13d268a627eb
# ╟─913bfc89-4174-4c37-a39a-7f7d75e9130d
# ╟─43edd2f5-a3cb-46af-8f02-645db056af23
# ╟─de58b85a-caae-4868-884e-fb7db7a45f26
# ╟─4c5618b3-582f-4f01-8cc0-ac5ca584e488
# ╟─1a30a559-410c-499c-a6fd-167e83ff0cda
# ╟─31155601-fdc8-415a-a100-9bf1b646501b
# ╟─61c20e22-d13c-4b44-b150-b0454c15079e
# ╟─bbe77ac3-f557-4a29-a1d7-cf692a822109
# ╟─93f53bc7-e719-498f-99b8-e34f5f2ae1d0
# ╟─1374d553-3be5-4538-ae27-3f81cc715a0f
# ╟─529568cb-274f-4b8f-8b3a-dd605e233512
# ╟─b754d23a-7b97-42c4-a291-c9f6bf650c02
# ╟─d651a3df-1b6f-45ce-9dc0-117be16d2757
# ╟─4ec853ff-c781-43a0-902e-1ee572a0dbcd
# ╟─1c47167f-bc44-4fae-a9b7-fc173777f9b1
# ╟─a6ba3cff-943b-4b1d-a999-eb2de14ca96a
# ╟─c7416938-8563-4c53-8ef0-b00dae70914c
# ╟─9d5e813b-3c55-4743-9abb-a82176ebad41
# ╟─15173aea-dbf7-4534-ba07-dc2d3baf285e
# ╟─a1897a4a-d26e-4bf9-9fe8-054b8be1b9b0
# ╟─bd879134-910e-430a-b0c1-8a1f98b4cabf
# ╟─ca69f861-5465-44cc-85b6-4a8f1100ba58
# ╟─2c34f920-69a8-43a9-871d-2222576f80ee
# ╟─1d19d1f9-9128-4a58-aced-bcee6f5b13b1
# ╟─4cc1c8aa-4229-4716-8976-6b6d7677c4fa
# ╟─a28a5176-9786-4af6-afaf-4c731470d3c5
# ╟─63c739bb-6712-4662-b616-f1260ed4f61e
# ╟─5b93995c-493f-4b10-8f4a-7ac93eff53ca
# ╟─cbca09fb-df4b-49bf-9569-6c52d7d21ec1
# ╟─f3a7a9f4-4bb9-4689-b3d2-1cea153abff1
# ╟─4feec265-94c7-4cc1-b8e6-f6fc4dc1b5d5
# ╟─5805a823-a88b-4d47-ba84-990a3669de61
# ╟─4ce3bbdf-c166-45e4-918e-9984c6f59803
# ╟─422b2a56-9123-4921-b909-7a8916567b14
# ╟─c1556b23-2ef0-44d2-a003-376d8dca52e6
# ╟─7251609e-9741-4dc6-bb63-97c7e38f3b44
# ╟─e6afa968-c606-4008-b99b-9aa647a69517
# ╟─3b2b8c33-d488-4794-bd25-e04f969d264f
# ╟─e8ab992c-6e93-448b-9add-9419fbf88641
# ╟─7cf84a90-4fe1-424f-926b-a9498835056b
# ╟─2bd94dbd-bda6-4c8c-aaba-19a7949d8c61
# ╟─e2069793-a762-41bb-a060-478212b966b6
# ╟─32296750-291b-4fab-a854-253f26dfb115
# ╟─0db1e121-0d39-4cd0-88c0-62be88dec20b
# ╟─45ffd3d0-28ce-4f19-8188-d8c5c25df69b
# ╟─45bc5b5c-e022-4053-aed1-efee98944e43
# ╟─08b56c59-47b4-4315-88d6-395bd72ac412
# ╟─fdf8029b-5e66-4586-bca1-eb0f3a0afe93
# ╟─f2cde942-fbe4-4648-bb00-185f98870207
# ╟─810ba824-3e29-43ea-ac88-ac416067baa4
# ╟─4f38d2d7-782c-427c-88e6-379edd65195d
# ╟─fc31fed5-b326-4122-8ca8-59d4774c7775
# ╟─b526cb00-1b92-4243-9d18-c9f592f48b5d
# ╟─4b1750dc-6f0d-40b2-8962-66bb635afa7d
# ╟─152ef7c6-f966-4d15-a68b-3e70b99864a1
# ╟─b019228d-1056-43d8-a2c3-7965d578b48f
# ╟─5028541e-5411-45ce-8b86-5d32311c8951
# ╟─4078fc42-f401-44c5-8933-13fb656a24ba
# ╟─8927a56d-528f-49ba-8184-3af4f3d73905
# ╟─3c0fb676-e7c2-4eba-a3bf-4673217d6a6a
# ╟─a6d42a16-cf7e-4101-bb67-c67b08d046a8
# ╟─4a1c5902-9557-43ea-b74f-0ab0f1bb3666
# ╟─2b7166ec-8908-464d-8a38-c4a31d8835c9
# ╟─ee9eb19b-b0de-4e83-8851-d3b7defa4576
# ╟─57aab465-2225-4f7b-be1b-599bda427ba8
# ╟─3711f6d7-a418-4563-94a5-dd754e438247
# ╟─d68d0b72-d7a5-4d50-ad27-4b8e8d19ada1
# ╟─533ba422-c467-4ed6-854c-2989a1f7631e
# ╟─578a4f0d-3626-459b-8dc7-e7069b875f37
# ╟─60f54380-64fb-4c92-9a42-4395417464cc
# ╟─b4804a6c-772b-4309-bbcc-24827263ccdc
# ╟─8da7cbd0-7a3f-4a6e-8e6a-71ca386df76c
# ╟─6860b5d8-78df-45f8-82dd-2691443d7b17
# ╟─039f5036-b6f0-46dd-9735-c0ef1bbe2650
# ╟─df5a1f92-c1c3-4437-955f-2e323a35932b
# ╟─585d9685-88d7-4a02-8ac8-d60e8b40e0ec
# ╟─235b1120-dcaf-44a9-9130-281fe5fac74a
# ╠═2afc2384-be8b-41f6-a2fa-858bcc615474
# ╠═0089c457-42a2-4080-97b4-be8d8ca1ff2d
# ╟─cc3852c0-4982-4d05-b467-cf28fd0b5c41
# ╟─727b5b19-52e3-44ce-8661-a48222619910
# ╟─76966f7e-840a-4434-952b-f179d72c57a6
# ╟─21978ad7-a56c-4959-b491-63d187b5f927
# ╟─14b4be96-bbad-420e-be13-1b55ea5618d8
# ╟─37c5ef80-2f0a-40f2-a687-b239115ddc0f
# ╟─87f7886b-3fee-4440-b5aa-3262ba0a0c11
# ╟─82b8f813-10f5-4bcb-99e3-a534459402b0
# ╟─644f6302-6609-4ec2-9250-333410738141
# ╟─9eda219f-27f4-4ba5-8acf-b2b5a0ab8415
# ╟─7e7ad2e9-6c5c-4ac6-b228-f942f221f559
# ╟─15db15ab-8e3a-473f-a1c6-457bb41d792d
# ╟─44be4109-442f-4fb9-b360-34043ab8add8
# ╟─bbe1ae25-9d71-4501-954f-41c9d6f51998
# ╟─19931f1e-8be7-4116-9f44-ee3ea13f9b83
# ╟─cb3d296a-590d-447b-9578-b14c3e2661ae
# ╟─c0c754e1-a599-496f-8066-3d12d72083c9
# ╟─7644847b-c850-47c1-8662-31fba0130635
# ╟─88c967db-e214-4cb1-a719-8d4dc45464ba
# ╟─1ee65ad1-9f5d-418d-aa1c-d3ea4e923257
# ╟─596f6481-1324-4e0d-afe7-f2868f2bde31
# ╟─cb8fdf58-24c5-41b9-b4f4-04e138684297
# ╟─6675666b-4d43-4aef-bf2c-168c9869f80a
# ╟─1edda966-72e7-43c2-9cb6-004decabfc1f
# ╟─62c9b84d-2fd3-48b6-8f91-99539c6e2e2a
# ╟─23525253-82cf-467f-9bdf-59b7b07c45b2
# ╟─c0583f12-2cb7-4429-aa75-3291e5e4c18b
# ╟─17ed83aa-5bba-484b-bae6-2543f63df46f
# ╟─c6aa6ae2-2b64-4bfe-98bd-07bae4fa068e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
