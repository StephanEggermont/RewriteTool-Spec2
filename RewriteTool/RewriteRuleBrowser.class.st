"
A RewriteRuleBrowser is a tool that provides GUI for applying rewrite rule on certain scope of packages / classes / methods.

To open do next: RewriteRuleBrowser new openWithSpec

Instance Variables
	applyButton:		<ButtonModel>
	browseButton:		<ButtonModel>
	chosenMethods:		<OrderedCollection>
	classes:		<ListModel>
	methods:		<ListModel>
	packages:		<ListModel>
	rules:		<ListModel>
	scopeButton:		<ButtonModel>

applyButton
	- applies selected rule to selected scope

browseButton
	- browses selected rule class

chosenMethods
	- selected methods (scope)

classes
	- list of classes of selected package

methods
	- list of methods of selected class

packages
	- list of all packages in this image

rules
	- list of rewrie rules that were created using RewriteRuleBuilder tool

scopeButton
	- browses selected scope (package / class)

"
Class {
	#name : #RewriteRuleBrowser,
	#superclass : #SpPresenter,
	#instVars : [
		'rules',
		'packages',
		'classes',
		'methods',
		'environment',
		'applyButton',
		'browseButton',
		'editButton',
		'searchMorph',
		'classLabel',
		'methodLabel',
		'checkbox'
	],
	#category : #'RewriteTool-Core'
}

{ #category : #accessing }
RewriteRuleBrowser class >> buttonHeight [
	^ 40
]

{ #category : #accessing }
RewriteRuleBrowser class >> buttonWidth [
	^ 150
]

{ #category : #specs }
RewriteRuleBrowser class >> defaultSpec [
	^ SpBoxLayout newVertical
		add:
			(SpBoxLayout newHorizontal
				add:
					(SpBoxLayout newVertical
						add: #searchMorph height: self buttonHeight;
						add: #packages;
						yourself);
				add:
					(SpBoxLayout newVertical
						add: #classLabel height: self buttonHeight;
						add: #classes;
						yourself);
				add:
					(SpBoxLayout newVertical
						add: #methodLabel height: self buttonHeight;
						add: #methods;
						yourself);
				yourself);
		add:
			(SpBoxLayout newHorizontal
				add: #applyButton width: self buttonWidth;
				add: #rules width: self rulesWidth;
				add: #checkbox width: self buttonWidth;
				add: #browseButton width: self buttonWidth;
				add: #editButton width: self buttonWidth;
				yourself)
			height: self buttonHeight;
		yourself
]

{ #category : #'world menu' }
RewriteRuleBrowser class >> menuCommandOn: aBuilder [
	<worldMenu>
	(aBuilder item: 'RewriteRuleBrowser')
		parent: #Tools;
		action: [ RewriteRuleBrowser new openWithSpec ];
		icon: (self iconNamed: #configIcon)
]

{ #category : #accessing }
RewriteRuleBrowser class >> rulesWidth [
	^ 225
]

{ #category : #actions }
RewriteRuleBrowser >> allRules [
	| allRules |
	allRules := (RBTransformationRule subclasses collect: [ :each | each name ]) asOrderedCollection.
	allRules addAll: (RBCustomTransformationRule subclasses collect: [ :each | each name ]).
	self rules items: allRules
]

{ #category : #actions }
RewriteRuleBrowser >> apply [
	self applyRule: self rules selectedItem on: self environment
]

{ #category : #accessing }
RewriteRuleBrowser >> applyButton [
	^ applyButton
]

{ #category : #actions }
RewriteRuleBrowser >> applyRule: aRuleClass on: aCollection [
	| result |
	result := self getResultOfRule: aRuleClass appliedTo: aCollection.
	(ChangesBrowser changes: result builder changes) open
]

{ #category : #accessing }
RewriteRuleBrowser >> browseButton [
	^ browseButton
]

{ #category : #actions }
RewriteRuleBrowser >> browseRule [
	Smalltalk tools browser fullOnClass: (Smalltalk globals at: self rules selectedItem)
]

{ #category : #accessing }
RewriteRuleBrowser >> browsedEnvironment [
	^ RBBrowserEnvironment new
]

{ #category : #accessing }
RewriteRuleBrowser >> checkbox [
	^ checkbox
]

{ #category : #accessing }
RewriteRuleBrowser >> classLabel [
	^ classLabel
]

{ #category : #accessing }
RewriteRuleBrowser >> classes [
	^ classes
]

{ #category : #actions }
RewriteRuleBrowser >> classesChanged [
	(self isSelectedClassesNotNil and: [ self classes selectedItems isNotEmpty ])
		ifTrue: [ self fillMethodsPane ]
]

{ #category : #initialization }
RewriteRuleBrowser >> connectPresenters [
	rules whenSelectedItemChangedDo: [ self rulesChanged ].
	packages whenSelectionChangedDo: [ self packagesChanged ].
	classes whenSelectionChangedDo: [ self classesChanged ].
	applyButton action: [ self apply ].
	browseButton action: [ self browseRule ].
	editButton action: [ self editRule ].
	checkbox whenActivatedDo: [ self onlyCustomRules ].
	checkbox whenDeactivatedDo: [ self allRules ]
]

{ #category : #accessing }
RewriteRuleBrowser >> createSearchMorph [
	"^ searchMorph
		ifNil: [ (SearchMorph new
				model: self;
				updateSelector: #search:;
				ghostText: 'Search for Packages';
				yourself) asSpAdapter ]"
		^ searchMorph
		ifNil: [ SpMorphPresenter new morph: (SearchMorph new
				model: self;
				updateSelector: #search:;
				ghostText: 'Search for Packages';
				yourself) ]
]

{ #category : #accessing }
RewriteRuleBrowser >> editButton [
	^ editButton
]

{ #category : #actions }
RewriteRuleBrowser >> editRule [
	| aRule builder |
	aRule := (Smalltalk globals at: self rules selectedItem) new.
	builder := RewriteRuleBuilder new.
	builder sourcePanel code: aRule input.
	builder resultPanel code: aRule output.
	builder transformationRule matchPanel code: aRule lhs.
	builder transformationRule transformPanel code: aRule rhs.
	builder transformationRule ruleName: aRule class asString.
	builder transformationRule packageName: aRule class category asString.
	builder openWithSpec
]

{ #category : #accessing }
RewriteRuleBrowser >> environment [
	^ environment
]

{ #category : #accessing }
RewriteRuleBrowser >> environment: anOrderedCollection [
	environment := anOrderedCollection
]

{ #category : #actions }
RewriteRuleBrowser >> fillMethodsPane [
	| chosenMethods |
	chosenMethods := OrderedCollection new.
	self environment: self classes selectedItems.
	self classes selectedItems
		do: [ :eachClass | chosenMethods addAll: eachClass methodDict ].
	self methods items: chosenMethods.
	self methods resetListSelection.
	self methods selectIndex: 0
]

{ #category : #accessing }
RewriteRuleBrowser >> foundItems [
	^ self rules listItems select: [ :each | (Smalltalk globals at: each) superclass = RBCustomTransformationRule ]
]

{ #category : #actions }
RewriteRuleBrowser >> getResultOfRule: aRuleClass appliedTo: aCollection [
	^ RBSmalllintChecker
		runRule: (Smalltalk globals at: aRuleClass) new
		onEnvironment: (RBClassEnvironment classes: aCollection)
]

{ #category : #initialization }
RewriteRuleBrowser >> initialExtent [
	^ 850@500
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeButtons [
	applyButton label: 'Apply rule:'.
	applyButton disable.
	browseButton label: 'Browse rule'.
	browseButton disable.
	editButton label: 'Edit rule'
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeCheckbox [
	self checkbox label: 'Only custom rules'.
	"self checkbox
		whenBuiltDo: [ :widget | widget widget asSpAdapter hShrinkWrap ]"
	self checkbox
		whenBuiltDo: [ :widget | SpMorphPresenter new morph: widget widget ]
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeClasses [
	self classes beMultipleSelection.
	self classes sortingBlock: [ :a :b | a name < b name ].
	self classes icons: [ self iconNamed: #classIcon ]
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeLabels [
	checkbox label: 'Only custom rules'.
	"checkbox
		whenBuiltDo: [ :widget | widget widget asSpAdapter hShrinkWrap ]"
	checkbox
		whenBuiltDo: [ :widget | SpMorphPresenter new morph: widget widget ]
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeMethods [
	"self methods allowToSelect: false."
	self methods beSingleSelection.
	self methods display: [ :item | '    ' , item selector asString ]
]

{ #category : #initialization }
RewriteRuleBrowser >> initializePackages [
	self packages items: self browsedEnvironment packages.
	self packages display: [ :item | item name ].
	self packages sortingBlock: [ :a :b | a name < b name ].
	self packages beMultipleSelection.
	self packages icons: [ self iconNamed: #packageIcon ]
]

{ #category : #initialization }
RewriteRuleBrowser >> initializePresenters [
	self instantiateThePresenters.
	self initializeCheckbox.
	self initializeLabels.
self		initializeButtons.
self		initializePackages.
self		initializeClasses.
self		initializeMethods.
self		initializeRules.
self 		setFocus.
self		environment: OrderedCollection new.
		
]

{ #category : #initialization }
RewriteRuleBrowser >> initializeRules [
	self allRules.
	self rules display: [ :item | item asString ]
]

{ #category : #initialization }
RewriteRuleBrowser >> instantiateThePresenters [
	rules := self newDropList.
	packages := self newList.
	classes := self newList.
	methods := self newList.
	applyButton := self newButton.
	browseButton := self newButton.
	editButton := self newButton.
	classLabel := self newLabel.
	methodLabel := self newLabel.
	checkbox := self newCheckBox.
	searchMorph := self createSearchMorph .
]

{ #category : #testing }
RewriteRuleBrowser >> isSelectedClassesNotNil [
	^ self classes selectedItems allSatisfy: [ :class | class isNotNil ]
]

{ #category : #accessing }
RewriteRuleBrowser >> methodLabel [
	^ methodLabel
]

{ #category : #accessing }
RewriteRuleBrowser >> methods [
	^ methods
]

{ #category : #actions }
RewriteRuleBrowser >> onlyCustomRules [
	self rules items: self foundItems
]

{ #category : #accessing }
RewriteRuleBrowser >> packages [
	^ packages
]

{ #category : #actions }
RewriteRuleBrowser >> packagesChanged [
	((self packages selectedItems
		allSatisfy: [ :package | package isNotNil ])
		and: [ self packages selectedItems isNotEmpty ])
		ifTrue: [ self environment: OrderedCollection new.
			self packages selectedItems
				do: [ :each | self environment addAll: each classes ].
			self classes items: self environment.
			self classes resetListSelection.
			self classes selectIndex: 0 ]
]

{ #category : #accessing }
RewriteRuleBrowser >> rules [
	^ rules
]

{ #category : #actions }
RewriteRuleBrowser >> rulesChanged [
	self rules selectedIndex = 0
		ifFalse: [ 
			self browseButton enable.
			self applyButton enable ]
		ifTrue: [ 
			self browseButton disable.
			self applyButton disable ]
]

{ #category : #actions }
RewriteRuleBrowser >> search: aString [
	| foundItems |
	aString = ''
		ifTrue: [ self packages items: self browsedEnvironment packages ]
		ifFalse: [ 
			foundItems := self browsedEnvironment packages select: [ :each | '*' , aString , '*' match: each name asString ].
			self packages items: foundItems.
			(foundItems isEmpty or: [ foundItems anySatisfy: [ :any | any isNil ] ])
				ifTrue: [ self classes items: OrderedCollection new ]
				ifFalse: [ self packagesChanged ] ]
]

{ #category : #initialization }
RewriteRuleBrowser >> setFocus [
	self focusOrder
		add: rules;
		add: packages;
		add: classes;
		add: methods;
		add: applyButton;
		add: browseButton;
		add: editButton.
]

{ #category : #actions }
RewriteRuleBrowser >> title [
	^ 'RewriteRuleBrowser' translated
]
