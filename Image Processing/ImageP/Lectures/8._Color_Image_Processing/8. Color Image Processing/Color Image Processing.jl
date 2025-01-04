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
	using PlutoUI,Images,TestImages, Plots, LaTeXStrings, ColorSchemes, ImageUtils

hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
note(text) = Markdown.MD(Markdown.Admonition("note", "Note", [text]))
example(text) = Markdown.MD(Markdown.Admonition("note", "Example", [text]))
definition(text) = Markdown.MD(Markdown.Admonition("correct", "Definition", [text]))
extra(text) = Markdown.MD(Markdown.Admonition("warning", "Additional Information", [text]))
	
	PlutoUI.TableOfContents()
end

# ╔═╡ b17eb2a9-d801-4828-b0cd-5792527a10d8
md"""
# 8. Image Processing - Color Image Processing
[Institute for Biomedical Imaging](https://www.tuhh.de/ibi/home.html), Hamburg University of Technology

* 👨‍🏫 Lecture: [Prof. Dr.-Ing. Tobias Knopp](mailto:tobias.knopp@tuhh.de) 
* 🧑‍🏫 Exercise: [Konrad Scheffler, M.Sc.](mailto:konrad.scheffler@tuhh.de)
"""

# ╔═╡ bdae42a3-8dbe-41ec-911a-89b087b26286
md"## 8.1 Overview

Until now we only handled images with a single value per pixel. In this lecture we discuss how this translates to color images.

A color image can be interpreted as *multi-channel image* with three different color channels. The function $f$ representing the image is a mapping

$f: \Omega \rightarrow  [0,1]^3.$

Each pixel value is thus a vector

$f(\mathbf{r}) = \begin{pmatrix} f_\text{r}(\mathbf{r}) \\ f_\text{g}(\mathbf{r}) \\ f_\text{b}(\mathbf{r}) \end{pmatrix}$

where $f_\text{r}(\mathbf{r})$, $f_\text{g}(\mathbf{r})$, and $f_\text{b}(\mathbf{r})$ are the scalar channels representing the colors red, green, and blue. 

The space covered by the three colors is called the [color space](https://en.wikipedia.org/wiki/Color_space). RGB is the default color space used in digital image processing most of the time.
"

# ╔═╡ fc897666-3549-4a14-a9f0-02a6d1779947
md"Let us load an image and look at the individual channels:"

# ╔═╡ cd82188b-9e0b-462e-8a77-0c7f4ab78833
begin
  mandril = testimage("mandril")
  plot(
   heatmap(mandril, title="colored"),
   heatmap(Gray.(red.(mandril)), title="red"),
   heatmap(Gray.(green.(mandril)), title="green"),
   heatmap(Gray.(blue.(mandril)), title="blue"),
	layout=(1,4), size=(800,200)
  )
end

# ╔═╡ f1e68b1e-53b3-4d00-84d8-607bc8d52f00
md"[RGB](https://en.wikipedia.org/wiki/RGB_color_model) is an additive color space where a value of 1 means that the color is fully present while a value of 0 means that the color is not present at all. In the image of Lena we can see that the red channel is much brighter then the other ones.

We have shown the individual color channels as grayscale images such that the intensity of the different channels can be directly compared. Instead we can also visualize them using the base colors:"

# ╔═╡ 6ac85bab-37ff-4cc2-b7db-0edbd2f080fd
begin
  plot(
   heatmap(mandril, title="colored"),
   heatmap(Colors.RGB.(red.(mandril),0,0), title="red"),
   heatmap(Colors.RGB.(0,green.(mandril),0), title="green"),
   heatmap(Colors.RGB.(0,0,blue.(mandril)), title="blue"),
	layout=(1,4), size=(800,200)
  )
end

# ╔═╡ c67f2604-8fc5-4f0f-ad8e-fddd4de3d23d
md"#### True Color and False Color

One can group colored image into two groups:
* **True color** images are those representing real objects that reflect with a certain wavelength.
* **False color** or **pseudocolor** images are those representing some abstract quantity using the color to transport the data in a way that the information is well received by a human observer.

An example of the first is the image of Lena. An example of the later would be a height map of a landscape.
"

# ╔═╡ b9d54f15-6d06-4759-8e84-eebac0325a7f
md"## 8.2 Color Fundamentals

Color is actually not a direct property of physical objects. Instead objects reflect light that appears as color in the visual perception system of humans. When using colors in digital devices we are trying to emulate this procedure.

The light traveling through space is the superposition of waves with different wavelengths. Sunlight, for instance, has a broad wavelength range being emitted, as is shown in the following picture:
"

# ╔═╡ b31aed77-df12-40bb-8efc-3789b20a7f65
LocalResource("img/Sonne_Strahlungsintensitaet.svg", :width=>500)

# ╔═╡ 6b47ee22-c8d8-48f1-9202-d9428a2d6801
md"The human eye can only detect a certain range of wavelengths (between 400 nm und 780 nm)."

# ╔═╡ c133a66c-1fdf-45d0-abb4-08db0dcb55f4
md"In the following image a human eye is shown. In the retina, the [photoreceptor cells](https://en.wikipedia.org/wiki/Photoreceptor_cell)  are detecting the light intensity. This information is then transported to the human brain via the optical nerve.
"

# ╔═╡ 01a1ce21-4888-46df-a01c-fe3613389175
LocalResource("img/Schematic_diagram_of_the_human_eye_en.svg")

# ╔═╡ 6cfd7042-943f-4e00-8169-771282ade2b1
md"There are two types of photoreceptor cells:
* [Rods](https://en.wikipedia.org/wiki/Rod_cell) are responsible for seeing in the dark. They only have one color channel and are perceived as gray values.
* [Cones](https://en.wikipedia.org/wiki/Cone_cell) are responsible for seeing colors and have three cone types (S,M,L). The S cone is perceived as blue, the M cone is perceived as green and the L cone is perceived as red. They react on the following wavelengths
"

# ╔═╡ 1819a32f-29da-40ba-91c7-7d7bc84ba16d
LocalResource("img/1416_Color_Sensitivity.jpg", :width=>500)

# ╔═╡ 85448ed7-a69f-4232-b6bf-58b30b05352e
md"What becomes apparent now is that the cones are generating a three-channel signal for a each wavelength and that our brain then combines them into one perceived color. The shown colors appear if the light has a single wavelength. In case of multiple wavelengths that are superimposing, one perceives a mixture."

# ╔═╡ 90c98f57-b6e2-40d8-887f-c8c58709d494
definition(md" The response to a stimulus with spectral composition $\Phi$ is given by the three integrated responses
		
$\begin{align}
			\nonumber L &= \int_0^\infty \Phi(\lambda) \bar L(\lambda) \text{d}\lambda\\
			\nonumber M &= \int_0^\infty \Phi(\lambda) \bar M(\lambda) \text{d}\lambda\\
			\nonumber S &= \int_0^\infty \Phi(\lambda) \bar S(\lambda) \text{d}\lambda,
		\end{align}$

where $\bar L$, $\bar M$, and $\bar S$ (sometimes without bar) are the cone response functions. We refer to these responses as *tristimulus values*.
	")

# ╔═╡ eb466285-7535-4468-87d4-2ae83d2b5d9b
note(md"The cones are on purpose not named RGB but SML (small, medium, long). This is because they are not related to a single color. For instance, when looking at a purely green wavelength, all three cones are receiving a signal. The signal is very small in the S cone, much larger in the M cone and a little bit lower in the L cone.")

# ╔═╡ ef7a86e0-4e4c-4ba9-adb7-0d95556326f5
md"Mixing is also shown in the following image where three different light sources (RGB) are used to create mixtures on a reflecting wall."

# ╔═╡ 269c8ed7-53a1-4cda-883a-ca604feb4c56
LocalResource("img/RGB_illumination.jpg")

# ╔═╡ ba0c3c68-a066-4a73-97fe-e8ef8a9dab66
md"One important thing now is that one can generate the same color in different ways. For instance:
* We can generate yellow by using a monochromatic light source with 580 nm wavelength
* We can take two light sources (540 nm (green) and 700 nm (red)) and mix them together.
"

# ╔═╡ 62cdf29d-c96b-4618-ba1e-bbd7dcadf507
md"This effect is called [metamerism](https://en.wikipedia.org/wiki/Metamerism_(color)) and is the basis of digital output devices."

# ╔═╡ 6cef6cfb-a786-4904-9226-7a65533b70d9
definition(md"**Grassmann's Laws** describe empirically the perception of mixtures of colored lights. \
 $\rightarrow$ **Symmetry law:** If color stimulus $A$ matches color stimulus $B$, then $B$ matches $A$ \
 $\rightarrow$ **Transitive law:** If $A$ matches $B$ and $B$ matches $C$, then $A$ matches $C$ \
$\rightarrow$ **Proportionality law:** If $A$ matches $B$, then $\alpha A$ matches $\alpha B$, $\alpha \ge 0$ \
  $\rightarrow$ **Additivity law:** If A matches B, C matches D, and $A+C$ matches $B+D$, then $A+D$ matches $B+C$

")

# ╔═╡ dd8cdb8e-a2ca-4bb3-ad2a-a8bb979cf887
md"### 8.2.1 Color Matching 

Since color is made in the human brain it is difficult to measure a perceived color. The connection between the wavelength spectrum and the perceived color was developed by the [International Commission on Illumination](https://en.wiki-
pedia.org/wiki/International_Commission_on_Illumination), see [CIE_1931_color_space](https://en.wikipedia.org/wiki/CIE_1931_color_space).

The idea is to take three different monochromatic light sources at standardized wavelengths of 700 nm (red), 546.1 nm (green) and 435.8 nm (blue) and try to match each color in the visible spectrum (generated by a monochromatic light source) by adding red, green and blue. The experimental setting looks like this:
"

# ╔═╡ 7a34314f-cc3f-44ac-80c2-2fd91792346d
LocalResource("img/colormatchingexperiment.png")

# ╔═╡ 1df68ed4-a4f3-455b-be48-85218ba8d9ca
md"The resulting color matching functions $\overline{r}(\lambda)$, $\overline{g}(\lambda)$, $\overline{b}(\lambda)$ look like this:"

# ╔═╡ 1ab624d5-9673-49b2-872a-2cab797ed814
let
  λ = range(350,750,length=1000)

  M =  1/0.17697*[0.49000 0.31000 0.20000; 0.17697 0.81240 0.01063; 0.00000 0.01000 0.99000]
  Minv = inv(M)
	
  r = [(Minv*[colormatch(l).x, colormatch(l).y, colormatch(l).z])[1] for l in λ]
  g = [(Minv*[colormatch(l).x, colormatch(l).y, colormatch(l).z])[2] for l in λ]
  b = [(Minv*[colormatch(l).x, colormatch(l).y, colormatch(l).z])[3] for l in λ]
  p = plot(λ,r, lw=2, c="red", label=L"\overline{r}(\lambda)", xlabel="λ/nm", size=(650,350))
  plot!(p, λ,g, lw=2, c="green", label=L"\overline{g}(\lambda)")
  plot!(p, λ,b, lw=2, c="blue", label=L"\overline{b}(\lambda)")
end

# ╔═╡ 47a97e8c-4a74-4883-82bc-e2bbee562704
md"The test pattern was swept from 380 nm to 780 nm and a set of people has adjusted the nobs to match the colors.

What is quite interesting are the negative values. These are colors on the spectrum that cannot be created using RGB. Instead one has added the amount of red to the test pattern to match the color."

# ╔═╡ 1283f664-0a69-46a6-a643-7f5e6f95e30b
note(md"You should now realize that our display technology cannot visualize all possible colors since they are also based on mixing RGB values and diodes cannot make negative light")

# ╔═╡ 740b8815-eb75-4db4-a16e-71c0369260f9
definition(md" Similar to the LMS tristimulus values we can define RGB tristimulus values as 

$\begin{align}
			\nonumber R &= \int_0^\infty \Phi(\lambda) \bar r(\lambda) \text{d}\lambda\\
			\nonumber G &= \int_0^\infty \Phi(\lambda) \bar g(\lambda) \text{d}\lambda\\
			\nonumber B &= \int_0^\infty \Phi(\lambda) \bar b(\lambda) \text{d}\lambda,
		\end{align}$
If we use the monochromatic light source with wavelength $\lambda$ we have $\Psi(\lambda) = \delta(\lambda)$, which means we determine $\bar r(\lambda)$, $\bar g(\lambda)$, and $\bar b(\lambda)$ by putting Dirac functions into this equation and looking at the RGB tristimulus values.
	")

# ╔═╡ 4fae8d48-7204-4d51-a80e-35b4750c4780
md"### 8.2.2 XYZ Color Space"

# ╔═╡ 02830f16-ca66-4139-9c96-730d6774c19d
md"Since negative values are difficult to handle, the international commission has introduced virtual values XYZ that can be transformed back and forth to RGB using the transformation:"

# ╔═╡ 5d534fad-ac2a-47d3-8de6-4102899ae71c
md"
${\displaystyle {\begin{pmatrix}X\\Y\\Z\end{pmatrix}}={\frac {1}{0.176\,97}}{\begin{pmatrix}0.490\,00&0.310\,00&0.200\,00\\0.176\,97&0.812\,40&0.010\,63\\0.000\,00&0.010\,00&0.990\,00\end{pmatrix}}{\begin{pmatrix}R\\G\\B\end{pmatrix}}}$
"

# ╔═╡ 4cf3f64a-6034-464e-aa11-09ed3ff80988
md"If we take the RGB stimulus functions $\overline{r}(\lambda)$, $\overline{g}(\lambda)$, $\overline{b}(\lambda)$ and calculate the associated $\overline{x}(\lambda)$, $\overline{y}(\lambda)$, $\overline{z}(\lambda)$ we obtain:"

# ╔═╡ e6572490-8d91-4e56-84b8-8d390b26521c
let
  λ = range(350,750,length=1000)
  x = [colormatch(l).x for l in λ]
  y = [colormatch(l).y for l in λ]
  z = [colormatch(l).z for l in λ]
  p = plot(λ,x, lw=2, c="red", label=L"\overline{x}(\lambda)", xlabel="λ/nm", size=(650,350))
  plot!(p, λ,y, lw=2, c="green", label=L"\overline{y}(\lambda)")
  plot!(p, λ,z, lw=2, c="blue", label=L"\overline{z}(\lambda)")
end

# ╔═╡ 652e47a7-7c73-42c9-a06e-833127bb42bf
md"We can now derive normalized values

$\begin{align}
x &= \frac{X}{X+Y+Z} \\
y &= \frac{Y}{X+Y+Z} \\
z &= \frac{Z}{X+Y+Z} = 1 - x - y
\end{align}$
which allows us to express the color by just the two values xy which can be used to draw a [chromaticity](https://en.wikipedia.org/wiki/Chromaticity) diagram: 
"

# ╔═╡ db84b3b8-3efe-4f4d-95b2-f31c3f415a9c
LocalResource("img/CIE1931xy_CIERGB.svg",:width=>400)

# ╔═╡ 02a7f984-064c-4d43-884f-43b62117fb46
md"This is  named the color gamut and it looks like a horse shoe. The three dots are the three base colors RGB and within the triangle one has all the colors that can be created using (positive) RGB mixing. On the upper left are the colors that cannot be created using RGB. With XYZ we can now represent all possible colors in the specified wavelength range."

# ╔═╡ 6315704b-cd41-4471-898b-52b378ba85c7
note(md"One can also normalize the RGB values leading to rgb values and derive a color gamut for RGB colors.")

# ╔═╡ 996654ae-f667-4bde-b84f-4df1779f3384
md"### 8.2.3 HSB/HSV Color Space"

# ╔═╡ 21cc5bd4-a199-45f3-996e-0f1ee8799efc
md"Instead of RGB and XYZ we can also characterize a color by the three terms
* **brightness**: This describes how dark a color is.
* **hue**: This describes the dominant wavelength in the color.
* **saturation**: This describes the colorfulness.
This is named the HSB or HSV color space.
"

# ╔═╡ 66765ba5-13db-4b6c-bdc0-1a90b42dfd6c
LocalResource("img/HSV_color_solid_cylinder_saturation_gray.png", :width=>500)

# ╔═╡ f15e55dc-7111-4c61-aa32-b926cf44309e
md"
Lets play around with this:

H =  $(@bind H Slider((range(0,360,length=256)); default=0, show_value=true)) 

S =  $(@bind S Slider((range(0,1,length=256)); default=0, show_value=true)) 

B =  $(@bind B Slider((range(0,1,length=256)); default=0, show_value=true))
"

# ╔═╡ 25bd66eb-e5b6-465b-85e4-77f6cca4b648
HSB(H,S,B)

# ╔═╡ bfa0f829-5cec-4bd0-92af-6509aa487a28
md"Basically what is happening here is that you select a base color and then either make it darker by putting black to it (brightness change) or you put white to it (saturation change).
"

# ╔═╡ 092cea73-7d45-45aa-bb49-ad18f4695230
md"
The brightness of an image is related to the [luminance](https://en.wikipedia.org/wiki/Luminance) which is the total amount of light being transmitted.

Hue and saturation can be combined to be the [chromaticity](https://en.wikipedia.org/wiki/Chromaticity) of a color, which is the value chosen in the color gamut before.


"

# ╔═╡ 359a589e-69f3-454b-8f34-9406183a25ac
md"### 8.2.4 RGB Color Space

We already introduced the RGB color space and how it historically arose. RGB is a device dependent color space since the location of the R, G, and B primitives in the xy chromacity diagram is not uniquely defined, i.e. there exist different definitions and standards. This is why in practice it requires proper [color management](https://en.wikipedia.org/wiki/Color_management) with [color profiles](https://en.wikipedia.org/wiki/ICC_profile) that characterize a color input or output device.

When using RGB in the computer, the values are normalized to the range $[0,1]$, sometimes also [0,255] when considering 8-bit values. Furthermore the values are often non-linearly transformed using a gamma transformation to account for the fact that the sensitivity of the human eye for bright colors is different than for dark colors.
"

# ╔═╡ 4264639b-002d-4a13-9884-4220f4b3fa1e
md"Let us have a look at the [sRGB](https://en.wikipedia.org/wiki/SRGB) profile, which is the one being regularly used (e.g. in the web).

To convert  sRGB values $R_{\mathrm {srgb} }$, $G_{\mathrm {srgb} }$, $B_{\mathrm {srgb} }$ to CIE XYZ we first need to apply the non-linear transformation

${\displaystyle C_{\mathrm {linear} }={\begin{cases}{\dfrac {C_{\mathrm {srgb} }}{12.92}},&C_{\mathrm {srgb} }\leq 0.04045\\[5mu]\left({\dfrac {C_{\mathrm {srgb} }+0.055}{1.055}}\right)^{\!2.4},&C_{\mathrm {srgb} }>0.04045\end{cases}}}$

where $C$ is $R$, $G$, or $B$.

These gamma-expanded values (sometimes called *linear values* or *linear-light values*) are multiplied by the following matrix to obtain CIE XYZ:


${\displaystyle {\begin{bmatrix}X\\Y\\Z\end{bmatrix}}={\begin{bmatrix}0.4124&0.3576&0.1805\\0.2126&0.7152&0.0722\\0.0193&0.1192&0.9505\end{bmatrix}}{\begin{bmatrix}R_{\text{linear}}\\G_{\text{linear}}\\B_{\text{linear}}\end{bmatrix}}}$
"

# ╔═╡ 05a8df4b-0c08-4bdf-a73e-10d06b6244db
md"This matrix can be derived from the table

Chromaticity | Red | Green | Blue | White point
------------ | --- | ----- | ---- | -----------
x | 0.6400 | 0.3000 | 0.1500 | 0.3127
y | 0.3300 | 0.6000 | 0.0600 | 0.3290
Y | 0.2126 | 0.7152 | 0.0722 | 1.0000

that specifies where in the xy diagram the RGB primitives lay. Since $xy$ are normalized values it is also necessary to report $Y$ which can be used to recover $XYZ$.
"

# ╔═╡ dfe00346-604c-4432-9690-68d672a0de7c
md"Geometrically the RGB colors are usually shown as a cube:"

# ╔═╡ 63433eb6-0dff-474d-9589-64d066331655
LocalResource("img/424px-RGB_Cube_Show_lowgamma_cutout_b.png", :width=>500)

# ╔═╡ cffbabd5-c0b4-4bdb-a208-3ce11b5189c0
md"
And of course you can also play around with RGB in this notebook:

R =  $(@bind R_ Slider((range(0,1,length=256)); default=0, show_value=true)) 

G =  $(@bind G_ Slider((range(0,1,length=256)); default=0, show_value=true)) 

B =  $(@bind B_ Slider((range(0,1,length=256)); default=0, show_value=true))
"

# ╔═╡ b689f786-41e2-4d27-bba4-25f1d204d320
RGB(R_,G_,B_)

# ╔═╡ 6c5e3ba8-e481-43a1-a839-e672c2154f72
md"### 8.2.5 Example

We have now learned that colors can be represented in different [color spaces](https://en.wikipedia.org/wiki/Color_model). Let us apply this to the Lena image and look at the individual channels:
"

# ╔═╡ ec2d9962-06c1-4427-85d2-4257a9f5b4fe
begin
mandrilHSV = convert.(HSV, mandril)
mandrilXYZ = convert.(XYZ, mandril)
	
  plot(
   heatmap(mandril, title="colored"),
   heatmap(Gray.(red.(mandril)), title="red"),
   heatmap(Gray.(green.(mandril)), title="green"),
   heatmap(Gray.(blue.(mandril)), title="blue"),
   heatmap(mandril, title="colored"),
   heatmap(Gray.(getfield.(mandrilXYZ,:x)), title="X"),
   heatmap(Gray.(getfield.(mandrilXYZ,:y)), title="Y"),
   heatmap(Gray.(getfield.(mandrilXYZ,:z)), title="Z"),
   heatmap(mandril, title="colored"),
   heatmap(Gray.(getfield.(mandrilHSV,:h)./360), title="hue"),
   heatmap(Gray.(getfield.(mandrilHSV,:s)), title="saturation"),
   heatmap(Gray.(getfield.(mandrilHSV,:v)), title="brightness"),

	layout=(3,4), size=(800,600)
  )
end

# ╔═╡ 644cbb9a-2745-478e-ba6c-63b382647f4e
note(md"You might wonder why we do not discuss [CMY](https://en.wikipedia.org/wiki/CMY_color_model) or [CMYK](https://en.wikipedia.org/wiki/CMYK_color_model), which are well known subtractive color spaces. The reason is that CMYK is only important for printers that are based on this color model (i.e. laser printers).")

# ╔═╡ 0187704b-46b6-4ee6-9bdf-c4a361eec842
md"## 8.3 Color Processing

One important question is how all the image processing algorithms developed in the last lectures can be applied to colored images. 

The answer is simple: In the majority of cases one can apply the algorithms channel-wise. In a well-designed image-processing framework, image values are treated as small vectors for which the operations
* multiplication with a scalar
* addition
are supported. If the image processing algorithm just needs these two operations, then the algorithm will work both with scalars and with colors.

Let us try this out:
"

# ╔═╡ abe1b501-3278-43f9-bf74-70273f2c8b19
RGB(0.8,0.0,0.0) + RGB(0.0,0.8,0.0)

# ╔═╡ e27ee109-222f-4888-9b7b-2fb163a67e65
3*RGB(0.2,0.0,0.0)

# ╔═╡ 0fad50bd-a68e-4f28-aece-f233f319bd66
RGB(0.8,0.0,0.0) * RGB(0.0,0.8,0.0)

# ╔═╡ 6741f1ad-1ba7-484a-bc05-0618222db4a4
md"So you can see that only those operations are supported, which actually make sense.

In some algorithms the amplitude of a color is required. In this case one can work channel-wise, or use the brightness value as the amplitude. Julia uses the first approach such that:
"

# ╔═╡ c21b9207-6bcd-4f65-8feb-2d79ee1d1415
abs(RGB(0.8,0.0,0.0)) == RGB(0.8,0.0,0.0) 

# ╔═╡ fa076cc3-8779-4fc0-951c-555f84d8b14a
md"### 8.3.1 Example

Let us have a look at a simple Gaussian filter example:
"

# ╔═╡ 557aeade-ac54-4cfe-beae-a3980b23eb6a
let
  plot(
    heatmap(mandril, title="original"),
	heatmap( imfilter(mandril, Kernel.gaussian(5)), title="filtered" ),
	size = (600,300)
  )
end

# ╔═╡ cebba7b1-d358-42c3-8478-b0adbf5887e4
md"As you can see, the code just works since a convolution requires only additions an scalar multiplications."

# ╔═╡ 73220f98-f9b6-49b8-a411-9ab8d8d2e7a9
md"### 8.3.2 Color Data Types

Gray images are  stored on disk using integer values ranging from 8 bit to 64 bit. When doing image processing they are usually converted to floating point numbers (32 bit or 64 bit).

When switching to colored images we need to store the three values RGB, which are most of the time put next to each other in main memory (or file memory).

"

# ╔═╡ d525c19e-0cfc-49be-ab50-4718603fdb56
RGB{N0f8}(0.0,0.749,1.0)

# ╔═╡ c14ab385-4ae0-41d9-91c4-2da8ff4051e1
isbits(RGB{N0f8}(0.0,0.749,1.0))

# ╔═╡ afea48c6-fc36-4768-b389-ad8358aba68d
sizeof(RGB{N0f8}(0.0,0.749,1.0))

# ╔═╡ 3f5819e3-70da-4c77-9909-b1420cfc0612
md"Quite often, in addition to RGB an additional transparency channel is stored. This channel is also named the alpha channel and thus we store the four values as RGBA or ARGB. In the first case, the alpha channel is at the last position, in the second case, it is at the first position."

# ╔═╡ c4e4dbbe-c377-40ca-8271-7e3625c79f41
RGBA{N0f8}(0.0,0.749,1.0,0.5)

# ╔═╡ ed8d03e7-5c81-4bf1-aecc-696254592fe8
md"We here used the data type `N0f8` which is an 8 bit integer normalized to the range of [0,1]. In other programming languages this will simply be an 8 bit integer. The type `RGB{N0f8}` thus has 24 bits while `RGBA{N0f8}` has 32 bits.

Since it is beneficial for modern CPUs to have 32 bit alignment, the alpha channel is often used in non-transparent cases as well."

# ╔═╡ 221e656c-3470-4386-b9f4-9682a38d207b
md"## 8.4 Pseudocolors

Images are not only used for displaying data that we can detect optically but the are also used to [visualize general information](https://en.wikipedia.org/wiki/Information_visualization). Some examples are:
* height map of a landscape
* thermal imaging
* medical imaging
Here are some example images:"

# ╔═╡ 0e30af84-6d05-4581-aa3f-fbde2e17149c
md"**Height Map:**"

# ╔═╡ 20ddaa3b-9580-4cc7-8ab6-de8c54c61ed7
LocalResource("img/Pacific_elevation.jpg",:width=>400)

# ╔═╡ a550acda-bb18-4af8-b398-356a27c4d924
md"**Thermal imaging:**"

# ╔═╡ f75564a1-5c53-48eb-92d9-b959014bed2d
LocalResource("img/Passivhaus_thermogram_gedaemmt_ungedaemmt.png",:width=>400)

# ╔═╡ 0433e63b-8162-4351-a62a-e0ef14048eb1
md"**Magnetic Resonance Image of a Knee:**"

# ╔═╡ 096e219e-7953-43e7-961d-0ecc12da200b
LocalResource("img/Knee_MRI_113035_rgbcb.png",:width=>400)

# ╔═╡ 5b8e8f13-e827-4c7c-98a6-a2d7f36a50ea
md"We name such use of color [false color](https://en.wikipedia.org/wiki/False_color) or pseudocolor."

# ╔═╡ ac77250d-e0df-4730-9140-c9a12b907ad5
md"##### Why use color?

One might question why to use color at all in these applications. The reasons are:
* better perception
* encode multiple things simultaneously

Both are two different use cases and it is important to understand that color has to be used in an adequate fashion to reach these goals.
"

# ╔═╡ 47104150-f0a5-4eb6-b09a-fa1663941578
note(md"Using color just to make an image *look nicer* is not an adequate use of color. In fact it can imply that the visual perception is actually degraded. We see an example of this later.")

# ╔═╡ 87d1daa8-e02b-47e7-9421-0c3cf9fb16d1
md"### 8.4.1 Color Mapping"

# ╔═╡ c4ab38a3-5e35-4757-813c-c501204ba4e8
md"

##### Gray Colormap
A gray color $c$ is  represented in number form as an element of $[0, 1]$ where $0$ is the color black and $1$ is the color white. In-between all shades of gray are defined.

##### General Colormap
A general color $c$ is  represented as an RGB tuple $c = (r,g,b) \in [0,1]^3$. A colormap $\kappa : [0, 1] \rightarrow [0, 1]^3$ maps an input value between $0$ and $1$ to an output color.

"

# ╔═╡ 617fe0cf-24d3-4fa1-b770-af78528a1261
md"The colormap is defined on the domain of real numbers in the interval $[0, 1]$. In practice colormaps are build using a set of discrete colors. Using linear interpolation it is possible to define a continuous function based on the discrete values.

Let $c_k \in [0,1]^3$ for $k=1,\dots, K$ be $K$ colors. Then we can define

$\begin{align}
 \kappa(\alpha) =  &\begin{cases} c_{\beta} & \text{if} \;\beta\; \text{is an integer} \\
 (1-w)c_{\lfloor \beta \rfloor}  +  w c_{\lfloor \beta \rfloor+1} & \textrm{otherwise} 
 \end{cases}
\end{align}$

to be the linearly interpolated colormap with $\beta = \alpha (K-1) + 1$, which is $\alpha$ scaled to $[1,K]$, and weighting $w = \beta - \lfloor \beta \rfloor$.

"

# ╔═╡ c4101a04-b01b-43fc-a891-4dd54b5e18e4
md"
##### What do we need for Color Mapping?

* a colormap $\kappa(\alpha)$
* a minimal value $a_\text{min}$ that maps to the darkest color $\kappa(0)$
* a maximal value $a_\text{max}$ that maps to the brightest color $\kappa(1)$
"


# ╔═╡ a3291c63-9795-4958-83d3-384a3d825c55
md"##### Windowing

The mapping between a real valued quantity $a$ and the input to the colormap $\alpha$ is called windowing and
can be expressed by a function

$\begin{align}
g(a) = 
\begin{cases}
0, & \text{for } a \leq a_\text{min}\\
\frac{a-a_\text{min}}{a_\text{max}-a_\text{min}},& \text{for } a_\text{min}<a<a_\text{max}\\
1, & \text{for } a \geq a_\text{max}
\end{cases}
\end{align}$
"

# ╔═╡ 5dcd44c7-0ed6-4e3a-aaee-89b80e431f5d
let
  function g_(a, amin, amax)
    if a<amin
		return 0
	elseif a> amax
		return 1
	else
		return (a-amin)/(amax-amin)
	end
  end
  a = range(-2,2,length=100)
  p = plot(a, g_.(a,-1,1),lw=2, label=nothing, xlabel=L"a", ylabel=L"g", xticks=([-1:1:1;], [L"a_\textrm{min}", "0", L"a_\textrm{max}"]))
end

# ╔═╡ a355b3e8-021b-4090-8592-d8c6d198339b
md"
Instead of $a_\text{min}$ and $a_\text{max}$ it is also common to consider 
*  $\text{WW} = a_\text{max} − a_\text{min}$ (Window Width or Contrast)
*  $\text{WL} = (a_\text{max} + a_\text{min})/2$ (Window Level or Brightness)

"

# ╔═╡ d60fa08a-32ff-4edb-9891-e88b46c3be6b
md"#### Lets combine everything

To colorize a function $f(x,y)$ we apply for each position $x$,$y$: 

$f_\text{colorized} (x , y ) = \kappa (g (f (x , y )))$
"

# ╔═╡ dd7d8def-b89d-4387-abff-78d967f25e51
md"### 8.4.2 Colormaps

The following shows some colormaps that have been developed for the 2D plotting library [Matplotlib](https://matplotlib.org/stable/tutorials/colors/colormaps.html):
"

# ╔═╡ c61b7e0a-c837-45a5-9d61-7974d20c6864
LocalResource("img/colormaps.png")

# ╔═╡ 31826398-43c0-4427-acbb-e862509323e7
md"One should take the following into account when using a colormap:
* What do I actually want to encode in the color?
* Small value changes should result in small color changes.
* What happens if you convert the colormap to grayscale? Is it still sequential (monotonic)?
* What about color blindness

#### Abuse of Color

An example where these guidelines are not taken into account is the jet colormap, which looks like this:

"

# ╔═╡ 7c784010-fab9-4a0c-86c1-27d353336336
ColorSchemes.jet

# ╔═╡ fad861c5-a939-46f2-926a-a23bd629db91
md"Obviously, the idea of jet is to use as many colors as possible. It is basically a sampling of the light spectrum (i.e. a rainbow pattern).

But lets  convert this to gray:" 

# ╔═╡ 27414e8a-97b8-4009-bd14-7673befd220f
Gray.(ColorSchemes.jet)

# ╔═╡ 78c8c86b-ed3f-4f26-b77e-7bdc12011991
md"The issue now is that blue and red are  mapped to similar gray values and cannot be distinguished. What this implies can be seen in the following example where a wave-like function is illustrated:"

# ╔═╡ 0d394976-331b-40ff-91be-1f7d8435d07f
LocalResource("img/jet.png")

# ╔═╡ 5a66593b-2f0c-4ddb-b4c0-008cdde1143d
md"What you can see  is that the yellow regions are highlighted in the jet image while there is actually no reason for that when looking at the gray colorized image at the right. Consequently, a false impression is generated."

# ╔═╡ 3ff679ba-6579-4375-9731-d8148fc1ff39
note(md"In practice the best is to just use a perceptually uniform sequential colormap such as viridis. They have been [designed by color experts](https://bids.github.io/colormap/) and are a good default choice in most cases.")

# ╔═╡ 2139dd18-9e6f-4bae-bf63-0c4a3a36ffb2
md"### 8.4.3 Complex Coloring

As a more advanced topic we consider how to visualize complex numbers. We already know the following ways:
* display real and imaginary part separately
* display amplitude and phase separately
Both have their pros and cons depending on what you want to focus on. One issue of separate images is, however, that you cannot associate directly the different pixel informations.
"

# ╔═╡ 842ac4e8-dc7d-463f-a127-91c3c5f42c57
md"Let us look at the following function

$f(x,y) = \cos(2\pi 5x)\cos(2\pi 5y)\,\exp(0.5 \text{i})$

which is one cosine transform basis function multiplied by a phase to make it complex (for illustration purpose):
"

# ╔═╡ 75384f2e-47cd-4ba2-9a86-37ac0c6aa332
begin
  img = [cos(2*pi*5*x)*cos(2*pi*5*y)*exp(0.4*im) for x=range(0,1,length=100), y=range(0,1,length=100)]

  plot(
	heatmap(real.(img), c=:grays, title="real"),
	heatmap(imag.(img), c=:grays, title="imag"),
	heatmap(abs.(img), c=:grays, title="abs"),
	heatmap(angle.(img), c=:grays, title="phase"), size=(700,480)
  );
end

# ╔═╡ 3530de25-b125-4136-a97e-9c31e05efbcc
md"##### Observations
* real/imag and abs/phase carry the same information but are differently perceived by the viewer.
* Whether the waves have maxima or minima is clear in the real/imag image but not in the abs image. One needs to additionally take the phase information into account.
"

# ╔═╡ ed3fd17b-6a1d-4f7f-91f9-f0c2235053ef
md"In order to get the best of both worlds it is possible to combine the abs and the phase image into a single image by exploiting colors.

The idea is to encode the absolute value in the brightness and encode the phase as a color:
"

# ╔═╡ 6b7224c0-fcdd-4a80-a379-676163e3d6fc
begin
 cbarImage = [x*exp(2*pi*im*y) for x=range(1,0,length=100), y=range(0,1,length=100)]
 plot(
   heatmap(ImageUtils.complexColoring(img),title="image"),
   heatmap(ImageUtils.complexColoring(cbarImage),title="colorbar", xticks=([1,50,100],[L"-\pi", L"0", L"\pi"]), xlabel="phase", ylabel="amplitude", yticks=([1,100],[L"1", L"0"])), size=(700,380)
	)
end

# ╔═╡ e02c9207-32dc-4c58-8515-4c854903fdaf
md"That is much nicer. The only downside is that it makes the colorbar a little bit more complex. In particular, the colormap is now 2D instead of 1D. In this notebook we build the colorbar on our own since Plots.jl has no build-in support for 2D colormaps."

# ╔═╡ f496afc5-1b72-45cd-9abe-95ddf13aaf94
note(md"The shown colormap is periodic since the phase is also periodic.")

# ╔═╡ bc8b8750-4e7a-48c3-8f9e-fa95d36499f8
md"## 8.5 Alpha Blending

In computer graphics, [alpha compositing](https://en.wikipedia.org/wiki/Alpha_compositing) or alpha blending is the process of combining one image with a background to create the appearance of partial or full transparency. It is often useful to render pixels in separate passes or layers and then combine the resulting 2D images into a single, final image called the composite.

"

# ╔═╡ 1ff69fe1-fa87-4221-ae98-39c9fc0ef03f
md"Given two image $A$ and $B$ there are various ways to combine the two images: "

# ╔═╡ d318d4dc-12ed-4605-b95a-7b512f70df5a
LocalResource("img/Alpha_compositing.svg", :width=>600)

# ╔═╡ 3a36f9ba-6cfc-4455-b92f-3ac3d32b7567
md"We are here primarily discussing $A$ over $B$, which is the most important one.

As you can see in the image there are two ways to do the blending:
* opaque: this means that the color of the object laying on top is shown.
* partially-transparent: this means that the colors are mixed in the overlaying region."

# ╔═╡ 79ca24a8-e804-4481-895c-be6a69b9f6c5
md"Let us apply both in a typical scenario where you want to overlay some text on an image:"

# ╔═╡ 6d44a5e3-b89a-4de2-9dce-498e92f19035
begin
mandril_ = convert.(RGBA{N0f8}, testimage("mandril")) 
mandrilText_ = load("img/mandrilText.png")
mandrilText = [ RGBA{N0f8}(rgb.r, rgb.g, rgb.b, rgb.r > 0 ? 0.5 : 0.0 ) 
				 for rgb in mandrilText_ ]

blended =  load("img/mandrilTextBlended.png") # This will be done in the exercise
blendedOpaque = load("img/mandrilTextOlendedOpaque.png") # This will be done in the exercise

plot( heatmap(mandril_, title="Image A"),
	  heatmap(mandrilText, title="Image B"),
	  heatmap(mandril_ + mandrilText, title="A+B"),
	  heatmap(blendedOpaque,title="B over A (opaque)" ),
	  heatmap(blended,title="B over A (transparent)" ),
	  plot(legend=false,grid=false,foreground_color_subplot=:white),
	  layout = (3,2), size=(800,1200))
end

# ╔═╡ cea1d854-e8e9-4aa7-8bee-d6e1ff7f5f0e
md"You can see that the simple addition is wrong and leads to an integer overflow that simply wraps to a wrong color.

Both over operations accomplish the goal of generating a joint image. In the transparent version you can still look through the text. To see this better we can zoom in a little bit:"

# ╔═╡ b71c0877-4e51-478a-986c-90a9937a8e31
blended[130:220,200:300]

# ╔═╡ 7a49959d-e59c-4783-93b3-ae826a1814b8
blendedOpaque[130:220,200:300]

# ╔═╡ cad70c6f-b145-4fa1-8e01-dc5779e26f8c
md"
#### Implementation

The opaque over operation is  implement  like this

$C_{o} = \begin{cases}
C_{a} & \text{if } \alpha_{a}=1 \\
C_{b} & \text{else } 
\end{cases}$

Here $C_{o}$, $C_{a}$ and $C_{b}$ stand for the color components of the pixels in the output image, image $A$ and image $B$ respectively, applied to each color channel (red/green/blue) individually. $\alpha_{a}$ is the alpha value of the image $A$, which controls, whether the pixel of image $A$ or $B$ is shown.

The tranparent over operator involves a convex combination of the colors:

$\begin{align}
\alpha_{o} &= \alpha_{a}+\alpha _{b}(1-\alpha_{a}) \\
C_{o} &= \frac{C_{a}\alpha _{a}+C_{b}\alpha_{b}(1-\alpha _{a})}{\alpha_{o}}
\end{align}$

whereas $\alpha_{o}$and $\alpha_{b}$ are the alpha values of the output image and image $B$ pixels."

# ╔═╡ c87a8f5b-d3e0-47f5-8625-3e0685b77f95
md"## 8.6 Wrapup

In this lecture you learned:
* what color is.
* that there are different types of color images (true color / false color).
* how to perform image processing on colored images.
* how to colorize images.
* how to do alpha blending.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ColorSchemes = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
ImageUtils = "8ad4436d-4835-5a14-8bce-3ae014d2950b"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
TestImages = "5e47fb64-e119-507b-a336-dd2b206d9990"

[compat]
ColorSchemes = "~3.24.0"
ImageUtils = "~0.2.11"
Images = "~0.26.0"
LaTeXStrings = "~1.3.1"
Plots = "~1.22.4"
PlutoUI = "~0.7.15"
TestImages = "~1.6.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "2384958e468be0cda3ad999ec22519513139f3b2"

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
git-tree-sha1 = "793501dcd3fa7ce8d375a2c878dca2296232686e"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.2"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "02f731463748db57cc2ebfbd9fbc9ce8280d3433"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.1"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "247efbccf92448be332d154d6ca56b9fcdd93c31"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.6.1"

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

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "0c5f81f47bbbcf4aea7b2959135713459170798b"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.5"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "601f7e7b3d36f18790e2caf83a882d88e9b71ff1"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "e0af648f0692ec1691b5d094b8724ba1346281cf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.18.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "70232f82ffaab9dc52585e0dd043b5e0c6b714f1"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.12"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "05f9816a77231b07e634ab8715ba50e5249d6f76"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "886826d76ea9e72b35fcd000e535588f7b60f21d"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c53fc348ca4d40d7b371e71fd52251839080cbc9"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.4"
weakdeps = ["IntervalSets", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

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
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

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

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.Extents]]
git-tree-sha1 = "2140cd04483da90b2da7f99b2add0750504fc39c"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.2"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

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
git-tree-sha1 = "b4fbdd20c889804969571cc589900803edda16b7"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.7.1"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "299dc33549f68299137e51e6d49a13b5b1da9673"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "2d6ca471a6c7b536127afccfa7564b5b39227fe0"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.5"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "d189c6d2004f63fd3c91748c458b09f26de0efaa"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.61.0"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "bc9f7725571ddb4ab2c4bc74fa397c1c5ad08943"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.69.1+0"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "d53480c0793b13341c40199190f92c611aa2e93c"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.3.2"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "424a5a6ce7c5d97cca7bcc4eac551b97294c54af"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.9"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "e94c92c7bf4819685eb80186d51c43e71d4afa17"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.76.5+0"

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
git-tree-sha1 = "899050ace26649433ef1af25bc17a815b3db52b7"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.9.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HistogramThresholding]]
deps = ["ImageBase", "LinearAlgebra", "MappedArrays"]
git-tree-sha1 = "7194dfbb2f8d945abdaf68fa9480a965d6661e69"
uuid = "2c695a8d-9458-5d45-9878-1b8a99cf7853"
version = "0.3.1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "eb8fed28f4994600e29beef49744639d985a04b2"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.16"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

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
git-tree-sha1 = "f5356e7203c4a9954962e3757c08033f2efe578a"
uuid = "cbc4b850-ae4b-5111-9e64-df94c024a13d"
version = "0.3.0"

[[deps.ImageContrastAdjustment]]
deps = ["ImageBase", "ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "eb3d4365a10e3f3ecb3b115e9d12db131d28a386"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.12"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "fc5d1d3443a124fde6e92d0260cd9e064eba69f8"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.1"

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
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "bca20b2f5d00c4fbc192c3212da8fa79f4688009"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.7"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils"]
git-tree-sha1 = "b0b765ff0b4c3ee20ce6740d843be8dfce48487c"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.3.0"

[[deps.ImageMagick_jll]]
deps = ["JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1c0a2295cca535fabaf2029062912591e9b61987"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.10-12+3"

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
git-tree-sha1 = "7ec124670cbce8f9f0267ba703396960337e54b5"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.10.0"

[[deps.ImageUtils]]
deps = ["AxisArrays", "ColorSchemes", "ColorVectorSpace", "Colors", "FFTW", "FixedPointNumbers", "ImageMagick", "Images", "Interpolations", "LinearAlgebra", "NIfTI", "Random", "Reexport", "Roots", "Statistics", "TestImages", "Unitful"]
git-tree-sha1 = "13c8bfdde5ecdac41a97717cac1167388adae2d3"
uuid = "8ad4436d-4835-5a14-8bce-3ae014d2950b"
version = "0.2.11"

[[deps.Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageBinarization", "ImageContrastAdjustment", "ImageCore", "ImageCorners", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "d438268ed7a665f8322572be0dabda83634d5f45"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.26.0"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3d09a9f60edf77f8a4d99f9e015e8fbf9989605d"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.7+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "ea8031dea4aff6bd41f1df8f2fdfb25b33626381"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.4"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "be8e690c3973443bec584db3346ddc904d4884eb"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "31d6adb719886d4e32e38197aae466e98881320b"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.0.0+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
deps = ["Dates", "Random"]
git-tree-sha1 = "3d8866c029dd6b16e69e0d4a939c4dfcb98fac47"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.8"
weakdeps = ["Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsStatisticsExt = "Statistics"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "4ced6667f9974fc5c5943fa5e2ef1ca43ea9e450"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.8.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "PrecompileTools", "Printf", "Reexport", "Requires", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "9bbb5130d3b4fa52846546bca4791ecbdfb52730"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.38"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "d65930fa2bc96b07d7691c652d701dcbe7d9cf0b"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f689897ccbe049adb19a065c495e75f372ecd42b"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.4+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "8c57307b5d9bb3be1ff2da469063628631d4d51e"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.21"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    DiffEqBiologicalExt = "DiffEqBiological"
    ParameterizedFunctionsExt = "DiffEqBase"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    DiffEqBase = "2b5f629d-d688-5b77-993f-72d75c75574e"
    DiffEqBiological = "eb300fae-53e8-50a0-950c-e21f52c2b7e0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "62edfee3211981241b57ff1cedf4d74d79519277"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.15"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

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

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "0f5648fbae0d015e3abe5867bca2b362f67a5894"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.166"

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
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "eb006abbd7041c28e0d16260e50a24f8f9104913"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2023.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "9ee1618cbf5240e6d4e0371d6f24065083f60c48"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.11"

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

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

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
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NIfTI]]
deps = ["Base64", "CodecZlib", "MappedArrays", "Mmap", "TranscodingStreams"]
git-tree-sha1 = "21e5b879564607ea98fb680c98a1b7838b7d7f1c"
uuid = "a3a9e032-41b5-5fc4-967a-a6b7a19844d3"
version = "0.6.0"

[[deps.NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "2c3726ceb3388917602169bed973dbc97f1b51a8"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.13"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "2ac17d29c523ce1cd38e27785a7d23024853a4bb"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.10"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "a4ca623df1ae99d09bc9868b008262d0c0ac1e4f"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.4+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a12e56c72edee3ce6b96667745e6cbbe5498f200"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.23+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "eed372b0fa15624273a9cdb188b1b88476e6a233"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.2"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "a935806434c9d4c506ba941871b327b96d41f2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "f92e1315dadf8c46561fb9396e525f7200cdc227"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.5"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "e7523dd03eb3aaac09f743c23c1a553a8c834416"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.22.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "bd7c69c7f7173097e7b5e1be07cee2b8b7447f51"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.54"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "240d7170f5ffdb285f9427b92333c3463bf65bf6"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.1"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "RecipesBase"]
git-tree-sha1 = "3aa2bb4982e575acd7583f01531f241af077b163"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "3.2.13"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "00099623ffee15972c16111bcf84c58a0051257c"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.9.0"

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
git-tree-sha1 = "9a46862d248ea548e340e30e2894118749dc7f51"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.5"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

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
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "7ad0dfa8d03b7bcf8c597f59f5292801730c55b8"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.4.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Roots]]
deps = ["ChainRulesCore", "CommonSolve", "Printf", "Setfield"]
git-tree-sha1 = "0f1d92463a020321983d04c110f476c274bafe2e"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "2.0.22"

    [deps.Roots.extensions]
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"
    RootsSymPyExt = "SymPy"
    RootsSymPyPythonCallExt = "SymPyPythonCall"

    [deps.Roots.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"
    SymPyPythonCall = "bc8888f7-b21e-4b7c-a06a-5d9c9496438c"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays"]
git-tree-sha1 = "792d8fd4ad770b6d517a13ebb8dadfcac79405b8"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.6.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "3aac6d68c5e57449f5b9b865c9ba50ac2970c4cf"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.42"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

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

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "5165dfb9fd131cf0c6957a3a7605dede376e7b63"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "f295e0a1da4ca425659c57441bcb59abb035a4bc"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.8.8"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Requires", "SparseArrays", "Static", "SuiteSparse"]
git-tree-sha1 = "03fec6800a986d191f64f5c0996b59ed526eda25"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.4.1"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "5ef59aea6f18c25168842bded46b16662141ab87"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.7.0"
weakdeps = ["Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StringDistances]]
deps = ["Distances", "StatsAPI"]
git-tree-sha1 = "ceeef74797d961aee825aabf71446d6aba898acb"
uuid = "88034a9c-02f8-509d-84a9-84ec65e18404"
version = "0.11.2"

[[deps.StructArrays]]
deps = ["Adapt", "ConstructionBase", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "0a3db38e4cce3c54fe7a71f831cd7b6194a54213"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.16"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

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

[[deps.TestImages]]
deps = ["AxisArrays", "ColorTypes", "FileIO", "OffsetArrays", "Pkg", "StringDistances"]
git-tree-sha1 = "f91d170645a8ba6fbaa3ac2879eca5da3d92a31a"
uuid = "5e47fb64-e119-507b-a336-dd2b206d9990"
version = "1.6.2"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "34cc045dd0aaa59b8bbe86c644679bc57f1d5bd0"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.8"

[[deps.TiledIteration]]
deps = ["OffsetArrays", "StaticArrayInterface"]
git-tree-sha1 = "1176cc31e867217b06928e2f140c90bd1bc88283"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.5.0"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "7209df901e6ed7489fe9b7aa3e46fb788e15db85"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.65"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "5f24e158cf4cee437052371455fe361f526da062"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.6"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "da69178aacc095066bad1f69d2f59a60a1dd8ad1"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.0+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

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
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

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
# ╟─fc897666-3549-4a14-a9f0-02a6d1779947
# ╟─cd82188b-9e0b-462e-8a77-0c7f4ab78833
# ╟─f1e68b1e-53b3-4d00-84d8-607bc8d52f00
# ╟─6ac85bab-37ff-4cc2-b7db-0edbd2f080fd
# ╟─c67f2604-8fc5-4f0f-ad8e-fddd4de3d23d
# ╟─b9d54f15-6d06-4759-8e84-eebac0325a7f
# ╟─b31aed77-df12-40bb-8efc-3789b20a7f65
# ╟─6b47ee22-c8d8-48f1-9202-d9428a2d6801
# ╟─c133a66c-1fdf-45d0-abb4-08db0dcb55f4
# ╟─01a1ce21-4888-46df-a01c-fe3613389175
# ╟─6cfd7042-943f-4e00-8169-771282ade2b1
# ╟─1819a32f-29da-40ba-91c7-7d7bc84ba16d
# ╟─85448ed7-a69f-4232-b6bf-58b30b05352e
# ╟─90c98f57-b6e2-40d8-887f-c8c58709d494
# ╟─eb466285-7535-4468-87d4-2ae83d2b5d9b
# ╟─ef7a86e0-4e4c-4ba9-adb7-0d95556326f5
# ╟─269c8ed7-53a1-4cda-883a-ca604feb4c56
# ╟─ba0c3c68-a066-4a73-97fe-e8ef8a9dab66
# ╟─62cdf29d-c96b-4618-ba1e-bbd7dcadf507
# ╟─6cef6cfb-a786-4904-9226-7a65533b70d9
# ╟─dd8cdb8e-a2ca-4bb3-ad2a-a8bb979cf887
# ╟─7a34314f-cc3f-44ac-80c2-2fd91792346d
# ╟─1df68ed4-a4f3-455b-be48-85218ba8d9ca
# ╟─1ab624d5-9673-49b2-872a-2cab797ed814
# ╟─47a97e8c-4a74-4883-82bc-e2bbee562704
# ╟─1283f664-0a69-46a6-a643-7f5e6f95e30b
# ╟─740b8815-eb75-4db4-a16e-71c0369260f9
# ╟─4fae8d48-7204-4d51-a80e-35b4750c4780
# ╟─02830f16-ca66-4139-9c96-730d6774c19d
# ╟─5d534fad-ac2a-47d3-8de6-4102899ae71c
# ╟─4cf3f64a-6034-464e-aa11-09ed3ff80988
# ╟─e6572490-8d91-4e56-84b8-8d390b26521c
# ╟─652e47a7-7c73-42c9-a06e-833127bb42bf
# ╟─db84b3b8-3efe-4f4d-95b2-f31c3f415a9c
# ╟─02a7f984-064c-4d43-884f-43b62117fb46
# ╟─6315704b-cd41-4471-898b-52b378ba85c7
# ╟─996654ae-f667-4bde-b84f-4df1779f3384
# ╟─21cc5bd4-a199-45f3-996e-0f1ee8799efc
# ╟─66765ba5-13db-4b6c-bdc0-1a90b42dfd6c
# ╟─f15e55dc-7111-4c61-aa32-b926cf44309e
# ╠═25bd66eb-e5b6-465b-85e4-77f6cca4b648
# ╟─bfa0f829-5cec-4bd0-92af-6509aa487a28
# ╟─092cea73-7d45-45aa-bb49-ad18f4695230
# ╟─359a589e-69f3-454b-8f34-9406183a25ac
# ╟─4264639b-002d-4a13-9884-4220f4b3fa1e
# ╟─05a8df4b-0c08-4bdf-a73e-10d06b6244db
# ╟─dfe00346-604c-4432-9690-68d672a0de7c
# ╟─63433eb6-0dff-474d-9589-64d066331655
# ╟─cffbabd5-c0b4-4bdb-a208-3ce11b5189c0
# ╠═b689f786-41e2-4d27-bba4-25f1d204d320
# ╟─6c5e3ba8-e481-43a1-a839-e672c2154f72
# ╟─ec2d9962-06c1-4427-85d2-4257a9f5b4fe
# ╟─644cbb9a-2745-478e-ba6c-63b382647f4e
# ╟─0187704b-46b6-4ee6-9bdf-c4a361eec842
# ╠═abe1b501-3278-43f9-bf74-70273f2c8b19
# ╠═e27ee109-222f-4888-9b7b-2fb163a67e65
# ╠═0fad50bd-a68e-4f28-aece-f233f319bd66
# ╟─6741f1ad-1ba7-484a-bc05-0618222db4a4
# ╠═c21b9207-6bcd-4f65-8feb-2d79ee1d1415
# ╟─fa076cc3-8779-4fc0-951c-555f84d8b14a
# ╠═557aeade-ac54-4cfe-beae-a3980b23eb6a
# ╟─cebba7b1-d358-42c3-8478-b0adbf5887e4
# ╟─73220f98-f9b6-49b8-a411-9ab8d8d2e7a9
# ╠═d525c19e-0cfc-49be-ab50-4718603fdb56
# ╠═c14ab385-4ae0-41d9-91c4-2da8ff4051e1
# ╠═afea48c6-fc36-4768-b389-ad8358aba68d
# ╟─3f5819e3-70da-4c77-9909-b1420cfc0612
# ╠═c4e4dbbe-c377-40ca-8271-7e3625c79f41
# ╟─ed8d03e7-5c81-4bf1-aecc-696254592fe8
# ╟─221e656c-3470-4386-b9f4-9682a38d207b
# ╟─0e30af84-6d05-4581-aa3f-fbde2e17149c
# ╟─20ddaa3b-9580-4cc7-8ab6-de8c54c61ed7
# ╟─a550acda-bb18-4af8-b398-356a27c4d924
# ╟─f75564a1-5c53-48eb-92d9-b959014bed2d
# ╟─0433e63b-8162-4351-a62a-e0ef14048eb1
# ╠═096e219e-7953-43e7-961d-0ecc12da200b
# ╟─5b8e8f13-e827-4c7c-98a6-a2d7f36a50ea
# ╟─ac77250d-e0df-4730-9140-c9a12b907ad5
# ╟─47104150-f0a5-4eb6-b09a-fa1663941578
# ╟─87d1daa8-e02b-47e7-9421-0c3cf9fb16d1
# ╟─c4ab38a3-5e35-4757-813c-c501204ba4e8
# ╟─617fe0cf-24d3-4fa1-b770-af78528a1261
# ╟─c4101a04-b01b-43fc-a891-4dd54b5e18e4
# ╟─a3291c63-9795-4958-83d3-384a3d825c55
# ╟─5dcd44c7-0ed6-4e3a-aaee-89b80e431f5d
# ╟─a355b3e8-021b-4090-8592-d8c6d198339b
# ╟─d60fa08a-32ff-4edb-9891-e88b46c3be6b
# ╟─dd7d8def-b89d-4387-abff-78d967f25e51
# ╟─c61b7e0a-c837-45a5-9d61-7974d20c6864
# ╟─31826398-43c0-4427-acbb-e862509323e7
# ╟─7c784010-fab9-4a0c-86c1-27d353336336
# ╟─fad861c5-a939-46f2-926a-a23bd629db91
# ╟─27414e8a-97b8-4009-bd14-7673befd220f
# ╟─78c8c86b-ed3f-4f26-b77e-7bdc12011991
# ╟─0d394976-331b-40ff-91be-1f7d8435d07f
# ╟─5a66593b-2f0c-4ddb-b4c0-008cdde1143d
# ╟─3ff679ba-6579-4375-9731-d8148fc1ff39
# ╟─2139dd18-9e6f-4bae-bf63-0c4a3a36ffb2
# ╟─842ac4e8-dc7d-463f-a127-91c3c5f42c57
# ╟─75384f2e-47cd-4ba2-9a86-37ac0c6aa332
# ╟─3530de25-b125-4136-a97e-9c31e05efbcc
# ╟─ed3fd17b-6a1d-4f7f-91f9-f0c2235053ef
# ╟─6b7224c0-fcdd-4a80-a379-676163e3d6fc
# ╟─e02c9207-32dc-4c58-8515-4c854903fdaf
# ╟─f496afc5-1b72-45cd-9abe-95ddf13aaf94
# ╟─bc8b8750-4e7a-48c3-8f9e-fa95d36499f8
# ╟─1ff69fe1-fa87-4221-ae98-39c9fc0ef03f
# ╟─d318d4dc-12ed-4605-b95a-7b512f70df5a
# ╟─3a36f9ba-6cfc-4455-b92f-3ac3d32b7567
# ╟─79ca24a8-e804-4481-895c-be6a69b9f6c5
# ╟─6d44a5e3-b89a-4de2-9dce-498e92f19035
# ╟─cea1d854-e8e9-4aa7-8bee-d6e1ff7f5f0e
# ╟─b71c0877-4e51-478a-986c-90a9937a8e31
# ╟─7a49959d-e59c-4783-93b3-ae826a1814b8
# ╟─cad70c6f-b145-4fa1-8e01-dc5779e26f8c
# ╟─c87a8f5b-d3e0-47f5-8625-3e0685b77f95
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
