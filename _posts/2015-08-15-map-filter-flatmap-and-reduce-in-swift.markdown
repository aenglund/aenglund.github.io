---
layout: post
title:  "Map, Filter, Flatmap and Reduce in Swift"
date:   2015-08-15 16:22:09
categories: software-development cocoa
---

Last year at WWDC, Apple released their new programming language, Swift. The development of the language has progressed real quick since the release, and by now Swift 2 is in Beta and available to developers through Apples Developer Portal. The release has been a great success and Swift has become one of the most beloved programming languages out there! As a twist, the language is also expected to be released as open-source this fall.

While the language makes it easier for developers to write code with greater expressiveness, readability, security and performance - It also marks a bigger interest in alternative programming paradigms. While Apples old programming language, Objective-C, is a C-based, object-oriented programming language - Swift could be categorized as a multi-paradigm language. The language is still strongly object-oriented, but Apple has also added support to use Swift in a more functional fashion. This is done by adapting some of the most well-known functional concepts and encurage the use of immutable objects.

Functional approaches has some great benefits over the object-oriented once; especially when it comes to concurrency and thread-safety. They also tends to be simpler to put under test since all functions are fully centered around input and output data of the function, and does not depend on global states or cause any side-effects.

I want to start by making a run-through on some of the higher-order functions, with their origins in functional programming languages, that has been added to Swift. These are; Map, Filter, Flatmap and Reduce. In Swift 2.0 these methods has been moved from a global scope into the CollectionType protocol.

### Map
{% highlight Swift %}
func map<T>(@noescape _ transform: (Self.Generator.Element) -> T) -> [T]
{% endhighlight %}

This is the function definition of the map function in Swift. At a first glimpse this might look a bit scary, but lets break it down! <i>func map</i> declares the function map. The <i>\<T\></i> part tells Swift that the type T is a placeholder for a class. This is known as a generic declaration. Declarations like this will stop the compiler from trying to look up the type T later in the declaration.

<i>@noescape</i> is an attribute in Swift that are used to communicate to the user of the function that the argument will not outlive the lifetime of the call. If the function dispatches to a different thread, an argument may be captured so that it exist at a later time when its needed. The @noescape attribute is a sign that this will not happen for this function.

The <i>_</i> means that the external parameter name is not needed when calling the function. <i>transform</i> is the name of the parameter.

The type of the parameter is declared as <i>(Self.Generator.Element) -> T</i>. This is a closure  that takes an argument of type Self.Generator.Element and returns an instance of type T. I will not explore SequenceType, GeneratorType etc. any further in this post, but for sake of clarity you can look at the Self.Generator.Element type as the same type of object as the type contained in the collection.

And finally <i>-> [T]</i> declares the return type of map. An array of T's.

What map does is that it takes the given closure and call that on every element in the collection. As we can understand by the function declaration, the result of the map function is an array of the same type as the return type of the closure. So the result will be a new array but with elements that are the result of calling the closure on the elements in the origin array. Note that Self.Generator.Type is the type of the argument to the closure, but T is the return type. This means that the new array don't necessarily need to contain objects of the same type as the origin array.

Here is an example on how it can be used in Swift.

{% highlight Swift %}
let devices = ["Phone", "Pad", "Mac"]
var prefixedDevices: [String] = devices.map {
    (let device) -> String in
    return "i" + device
}
// prefixedDevices = ["iPhone", "iPad", "iMac"]

// Or similar...
prefixedDevices = devices.map { "i" + $0 }
// prefixedDevices = ["iPhone", "iPad", "iMac"]
{% endhighlight %}

For illustrating purposes here is how to achieve the same thing in Objective-C.

{% highlight Objective-c %}
NSArray *devices = @[@"Phone", @"Pad", @"Mac"];
NSMutableArray *transformedDevices = [NSMutableArray arrayWithCapacity:[devices count]];
for (NSString *device in devices) {
    NSString *transformedDevice = [@"i" stringByAppendingString:device];
    [transformedDevices addObject:transformedDevice];
}
NSArray *prefixedDevices = [transformedDevices copy];
// prefixedDevices = @["iPhone", "iPad", "iMac"]
{% endhighlight %}

### Filter
{% highlight Swift %}
public func filter(@noescape includeElement: (Self.Generator.Element) -> Bool) -> [Self.Generator.Element]
{% endhighlight %}

Filter is a bit different from map in its declaration. The type of the includeElement parameter is a closure that takes a Self.Generator.Element and returns a boolean value. The return type of filter is also an array of the same type as the argument to the closure; Self.Generator.Element. What this means is that the resulting array will be an array with objects of the same type as the origin array.

The filter function calls the closure on every element, and if the closure returns True, then the element will be included in the new array.

{% highlight Swift %}
let devices: [String] = ["iPhone", "Samsung Galaxy", "iPad"]
var filteredDevices = devices.filter {
    (let device) -> Bool in
    return device[device.startIndex] == "i"
}
// filteredDevices = ["iPhone", "iPad"]

// Or similiar...
filteredDevices = devices.filter { $0[$0.startIndex] == "i" }
// filteredDevices = ["iPhone", "iPad"]
{% endhighlight %}

And again - Here is the same thing done in Objective-C.

{% highlight Objective-C %}
NSArray *devices = @[ @"iPhone", @"Samsung Galaxy", @"iPad" ];
NSMutableArray *mutableFilteredDevices = [NSMutableArray arrayWithCapacity:[devices count]];
for (NSString *device in devices) {
    NSString *firstLetter = [device substringToIndex:1];
    if ([firstLetter isEqualToString:@"i"]) {
        [mutableFilteredDevices addObject:device];
    }
}
NSArray *filteredDevices = [mutableFilteredDevices copy];
// filteredDevices = @["iPhone", "iPad"]
{% endhighlight %}

### Flatmap
{% highlight Swift %}
public func flatMap<S : SequenceType>(@noescape transform: (Self.Generator.Element) -> S) -> [S.Generator.Element]
{% endhighlight %}

Now, flatMap can be a bit harder to wrap your head around at first. Lets have a short break down of the declaration. 

A generic declaration <i>\<S : SequenceType></i> is used for referring a type that conforms to the SequenceType protocol. The argument for parameter <i>transform</i> should be a closure that takes an element in the collection which the flatMap function is called on, and return an object conforming to SequenceType. The return type of the flatMap function is then declared to be an array with objects of the same type as the closure argument.

FlatMap is handy to use when you are working with multi-dimensional arrays. Just like the map function the transform closure gets an element in the collection as argument, but the flatMap closure is expected to return a type conforming to SequenceType (eg. Array). What flatMap then does is that it flattens all these returned sequences and return that as an array.

{% highlight Swift %}
let shoppingBags = [["Banana", "Apple", "Orange"], ["Cornflakes"], ["Coffee", "Butter"]]
var shoppingBag = shoppingBags.flatMap {
    (let shoppingBag) -> [String] in
    return shoppingBag
}
// shoppingBag = [Banana, Apple, Orange, Cornflakes, Coffee, Butter]

// Or simillar...
shoppingBag = shoppingBags.flatMap { $0 }
// shoppingBag = [Banana, Apple, Orange, Cornflakes, Coffee, Butter]
{% endhighlight %}

So flatmap can help you remove a dimension in your array. You can of course do more things than just returning the array passed to the closure. I would say that flatmap is most powerful together with other higher-order functions. Here are some other use-cases.

{% highlight Swift %}
let shoppingBags = [["Banana", "Apple", "Chocolate"], ["Cornflakes", "Chocolate"], ["Coffee", "Butter"]]
let numberOfItemsInBags = shoppingBags.flatMap { [$0.count] }
// numberOfItemsInBags = [3, 2, 2]

let healthierShoppingBag = shoppingBags.flatMap {
    return $0.filter {
        $0 != "Chocolate"
    }
}
// healtherShoppingBag =  [Banana, Apple, Cornflakes, Coffee, Butter]

let persons = [["id": 1, "age": 30], ["id": 2, "age": 24], ["id": 3, "age": 36]]
let agesPlusOne = persons.flatMap { $0["age"] }.map { $0 + 1 }
// agesPlusOne = [31, 25, 37]
{% endhighlight %}

### Reduce
{% highlight Swift %}
func reduce<T>(initial: T, @noescape combine: (T, Self.Generator.Element) -> T) -> T
{% endhighlight %}

At last! Lets take a closer look at the reduce function and its declaration. A generic declaration is specified, <i>T</i>. Reduce has two parameters. First <i>initial</i>, an object of type T. Then the <i>combine</i> parameter which takes a closure as argument. The closure in turn takes an object of type T and an element in the collection the reduce function is called on as arguments. The closure should return an object of the same type as the first parameter. The return value of the reduce function is of type T.

The problem the reduce function solves is that it combines all elements in the collection into one single value. While the closure is called on every element in the collection, the initial argument to the closure will be the returned value from the closure for the previous element. 
The first element in the collection will have the initial argument to the reduce function as the inital argument to the closure. The returned value of the reduce function is the same value as returned from the closure when called on the last element.

{% highlight Swift %}
let ages = [10, 21, 24, 53]
var sumOfAges = ages.reduce(0) {
    (let initial, let element) -> Int in
    return initial + element
}
// sumOfAges = 108

// Since operators are functions we can do..
sumOfAges = ages.reduce(0, combine: +)
// sumOfAges = 108
{% endhighlight %}

Here is the same thing done in Objective-C.

{% highlight Objective-C %}
NSArray *ages = @[@(10), @(21), @(24), @(53)];
NSNumber *sumOfAges = @(0);
for (NSNumber *age in ages) {
    sumOfAges = @([sumOfAges integerValue] + [age integerValue]);
}
// sumOfAges = 108

// Or using collection operators
sumOfAges = [ages valueForKeyPath:@"@sum.self"];
// sumOfAges = 108
{% endhighlight %}

Of course reduce is not limited to numbers. It can be used with any data type that you can combine into a single value inside the closure.

### Conclusion
All these higher-order functions added to Swift can be really powerful, especially when chained with each other. I look forward into discover more of the functional programming concepts added to Swift, and getting used to use them effectively! I think that when you get into the mindset and get comfortable using these methods - You will probably change how you tackle those everyday programming tasks.
