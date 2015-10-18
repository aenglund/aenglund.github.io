---
layout: post
title:  "Be aware of your enumerated types"
date:   2015-10-18 13:40:09
categories: software-development cocoa
---

When you are working with Apples Foundation framework you have probably stumbled across NS_ENUM and NS_OPTIONS (since iOS 6 and OS X Mountain Lion). Both NS_ENUM and NS_OPTIONS are marcros that use the C enum under the hood, and if you have used C enums before you will probably understand these macros, kind of, right away. 

So why do we need these macros? NS_ENUM and NS_OPTIONS makes it easy for developers to specify the underlying type and size of your enumeration. This is handy since we, developers for Apple plattforms, may need to compile our applications to run on both 32-bit and 64-bits processor architectures. So by defining the type of the enumeration to be NSInteger or NSUInteger, the compiler can decide what the most appropriate size depending processor architecture.

In this post I am going to take a little deeper look at NS_OPTIONS and give a solution to a misstake I often see in the community when using the macro.

### NS_OPTIONS

If you are used to C enum, you may also be aware of that enum can be used as bitmasks. This is exactly the use case of NS_OPTIONS. The macro tells the compiler that the values can be combined with bitmask operators, <i>|</i> for bitwise or and <i>&</i> for bitwise and.

Here is an example from UIView.h in UIKit. This is the definition of UIViewAnimationOptions.

{% highlight Objective-c %}
typedef NS_OPTIONS(NSUInteger, UIViewAnimationOptions) {
    UIViewAnimationOptionLayoutSubviews            = 1 <<  0,
    UIViewAnimationOptionAllowUserInteraction      = 1 <<  1,
    UIViewAnimationOptionBeginFromCurrentState     = 1 <<  2,
    UIViewAnimationOptionRepeat                    = 1 <<  3,
    UIViewAnimationOptionAutoreverse               = 1 <<  4,
    UIViewAnimationOptionOverrideInheritedDuration = 1 <<  5,
    UIViewAnimationOptionOverrideInheritedCurve    = 1 <<  6,
    UIViewAnimationOptionAllowAnimatedContent      = 1 <<  7,
    UIViewAnimationOptionShowHideTransitionViews   = 1 <<  8,
    UIViewAnimationOptionOverrideInheritedOptions  = 1 <<  9,
    
    UIViewAnimationOptionCurveEaseInOut            = 0 << 16,
    UIViewAnimationOptionCurveEaseIn               = 1 << 16,
    UIViewAnimationOptionCurveEaseOut              = 2 << 16,
    UIViewAnimationOptionCurveLinear               = 3 << 16,
    
    UIViewAnimationOptionTransitionNone            = 0 << 20,
    UIViewAnimationOptionTransitionFlipFromLeft    = 1 << 20,
    UIViewAnimationOptionTransitionFlipFromRight   = 2 << 20,
    UIViewAnimationOptionTransitionCurlUp          = 3 << 20,
    UIViewAnimationOptionTransitionCurlDown        = 4 << 20,
    UIViewAnimationOptionTransitionCrossDissolve   = 5 << 20,
    UIViewAnimationOptionTransitionFlipFromTop     = 6 << 20,
    UIViewAnimationOptionTransitionFlipFromBottom  = 7 << 20,
} NS_ENUM_AVAILABLE_IOS(4_0);
{% endhighlight %}

In this definition the shift operator is used to define the values of the constants in the enumeration. For example 1 << 4. What this does is that it takes the bits for decimal 1, and scoot them to the left by four steps. 0 0 0 0 1 will then become 1 0 0 0 0. The value for UIViewAnimationOptionAutoreverse will therefore resolve to decimal 16.

By this definition, all options from UIViewAnimationOptionLayoutSubviews to UIViewAnimationOptionOverrideInheritedOptions can be combined together in any combination. Since these options are using decimal 1 with different shifting. Options can combined by using bitwise or <i>|</i>.

{% highlight Objective-c %}
UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse;
// options = 1 0 0 0 | 1 0 0 0 0 = 1 1 0 0 0 = 24
{% endhighlight %}

We can also check if an option is set in the bitmask by using the bitwise and <i>&</i>.

{% highlight Objective-c %}
UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse;
BOOL const shouldRepeat = (options & UIViewAnimationOptionRepeat);
// 1 1 0 0 0 & 1 0 0 0 = 0 1 0 0 0 = 8
// shouldRepeat = YES
{% endhighlight %}

### The problem

The previous example of checking a bitmask might be a sufficient solution in cases where every option is represented by one bit. If the bitmask should change, this solution may become broken depending on the change!

This is even more obvious when we look at both the options for the animation curve and the animation transition. As you can see in the definition of these options, the shifting is different from the first options. Instead of shifting the value 1 by different steps, different values are shifted with the same amount of steps. These options will therefore end up using the same bits in the resulting bitmask. When this is the case, all bits in the mask that is dedicated to this option needs to be considered when determining if an option is present in a bitmask or not.

Lets look at an example where the check for an option done in the previous example is an insufficient solution.

{% highlight Objective-c %}
UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
// shifting value 3 (binary 11) 16 steps
// options = 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 = 196608

UIViewAnimationOptions easeInOption = UIViewAnimationOptionCurveEaseIn;
// shifting value 1 (binary 1) 16 steps
// options = 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 = 65536

BOOL const curveIsEaseIn = (options & easeInOption);
// curveIsEaseIn = 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 & 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 = 65536
// curveIsEaseIn = YES
{% endhighlight %}

As you can see, when checking options against a bitmask like this can lead to an incorrect result. In my example the check says that the options contains ease in, which is not what I defined... It's enough for the options to have one bit in common in order for the result to turn into something other than 0 (false). So what would be a more sufficient way of checking if the animation curve is of type "ease in"?

A sufficient check requires that you know how the enumerated type is defined. So whenever I want to define these kinds of options I also create a corresponding function to check for a value in an option mask. This is great since if the enumerated type needs to be changed later on, there is just one place to change the values, instead of everywhere in the app. It also makes the check a lot more readable. 

Here is an example of a function that I would have added to check for an animation curve if I had options simillar to the UIViewAnimationOptions.

{% highlight Objective-c %}
static inline BOOL UIViewAnimationOptionsHasAnimationCurve(UIViewAnimationOptions options, UIViewAnimationOptions curve) {
    // Shift the options back 16 steps.
    // Then mask out other bits that are not used for the curve options.
    options = (options >> 16) & 3;
    // The same principle on the curve passed to the function
    curve = (curve >> 16) & 3;
    // Options and curve should now resolve to the same value if the curve is in the options mask
    return options == curve;
}

UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
BOOL hasEaseInAnimationCurve = UIViewAnimationOptionsHasAnimationCurve(options, UIViewAnimationOptionCurveEaseIn);
// hasEaseInAnimationCurve = NO
{% endhighlight %}

The decimal value 3 is used in the example above since it's binary representation is 11. Meaning that the two bits used for the animation curve will be kept, but other bits will be and-ed out by zeros.

As a practice for you, I leave the function for checking for a specific transition out. I hope you found this article interesting and that you gained some new insights. Happy coding!
