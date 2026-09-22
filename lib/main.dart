import 'package:expressions/expressions.dart';
import 'package:flutter/material.dart';

void main() {
	runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
	const CalculatorApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'GitHub Copilot Calculator',
			theme: ThemeData(
				brightness: Brightness.dark,
				colorScheme: ColorScheme.fromSeed(
					seedColor: const Color(0xffef8354),
					brightness: Brightness.dark,
				),
				fontFamily: 'sans-serif',
				scaffoldBackgroundColor: const Color(0xff101820),
				useMaterial3: true,
			),
			home: const CalculatorScreen(),
		);
	}
}

class CalculatorScreen extends StatefulWidget {
	const CalculatorScreen({super.key});

	@override
	State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
	String _expression = '';
	String _result = '';
	String _error = '';
	bool _justEvaluated = false;

	static const _operators = {'+', '-', '*', '/'};
	static const _buttonRows = [
		['C', '(', ')', '/'],
		['7', '8', '9', '*'],
		['4', '5', '6', '-'],
		['1', '2', '3', '+'],
		['0', '.', '=', 'x²'],
	];

	void _press(String value) {
		setState(() {
			if (value == 'C') {
				_clear();
			} else if (value == '=') {
				_evaluate();
			} else if (value == 'x²') {
				_square();
			} else {
				_append(value);
			}
		});
	}

	void _clear() {
		_expression = '';
		_result = '';
		_error = '';
		_justEvaluated = false;
	}

	void _append(String value) {
		if (_justEvaluated) {
			_expression = _operators.contains(value) ? _result : '';
			_result = '';
			_justEvaluated = false;
		}

		_error = '';
		if (_operators.contains(value)) {
			if (_expression.isEmpty && value != '-') return;
			if (_expression.isNotEmpty && _operators.contains(_expression[_expression.length - 1])) {
				_expression = '${_expression.substring(0, _expression.length - 1)}$value';
				return;
			}
		}

		if (value == '.') {
			final currentNumber = _expression.split(RegExp(r'[+*/()-]')).last;
			if (currentNumber.contains('.')) return;
			if (currentNumber.isEmpty) _expression += '0';
		}

		if (value == '(' && _expression.isNotEmpty && RegExp(r'[0-9)]').hasMatch(_expression[_expression.length - 1])) {
			_expression += '*';
		}
		if (value == ')' && (_expression.isEmpty || _expression.endsWith('(') || _operators.contains(_expression[_expression.length - 1]))) {
			return;
		}
		_expression += value;
	}

	void _evaluate() {
		if (_expression.isEmpty || _operators.contains(_expression[_expression.length - 1])) return;
		try {
			final parsed = Expression.parse(_expression);
			final value = const ExpressionEvaluator().eval(parsed, <String, dynamic>{}) as num;
			if (!value.isFinite) throw const FormatException('Cannot divide by zero');
			_result = _formatNumber(value.toDouble());
			_error = '';
			_justEvaluated = true;
		} catch (_) {
			_result = '';
			_error = 'Invalid expression';
			_justEvaluated = false;
		}
	}

	void _square() {
		if (_expression.isEmpty || _operators.contains(_expression[_expression.length - 1])) return;
		try {
			final parsed = Expression.parse(_expression);
			final value = const ExpressionEvaluator().eval(parsed, <String, dynamic>{}) as num;
			final squared = value * value;
			if (!squared.isFinite) throw const FormatException('Result is too large');
			_result = _formatNumber(squared.toDouble());
			_error = '';
			_justEvaluated = true;
		} catch (_) {
			_result = '';
			_error = 'Invalid expression';
			_justEvaluated = false;
		}
	}

	String _formatNumber(double value) {
		if (value == value.roundToDouble()) return value.toInt().toString();
		return value.toString();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Center(
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 460),
						child: Padding(
							padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									const Text(
										'GITHUB COPILOT',
										style: TextStyle(
											color: Color(0xffef8354),
											fontSize: 15,
											fontWeight: FontWeight.w700,
											letterSpacing: 2.4,
										),
									),
									const SizedBox(height: 6),
									const Text(
										'Calculator',
										style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
									),
									const SizedBox(height: 22),
									_Display(expression: _expression, result: _result, error: _error),
									const SizedBox(height: 16),
									Expanded(
										child: GridView.builder(
											physics: const NeverScrollableScrollPhysics(),
											gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
												crossAxisCount: 4,
												crossAxisSpacing: 10,
												mainAxisSpacing: 10,
												childAspectRatio: 1.35,
											),
											itemCount: 20,
											itemBuilder: (context, index) {
												final row = index ~/ 4;
												final column = index % 4;
												final value = _buttonRows[row][column];
												final isEquals = value == '=';
														final isOperator = _operators.contains(value) || value == '(' || value == ')' || value == 'x²';
												return _CalculatorButton(
													label: value,
													isAccent: isEquals,
													isOperator: isOperator,
													onPressed: () => _press(value),
												);
											},
										),
									),
								],
							),
						),
					),
				),
			),
		);
	}
}

class _Display extends StatelessWidget {
	const _Display({required this.expression, required this.result, required this.error});

	final String expression;
	final String result;
	final String error;

	@override
	Widget build(BuildContext context) {
		return Container(
			constraints: const BoxConstraints(minHeight: 142),
			padding: const EdgeInsets.all(22),
			decoration: BoxDecoration(
				color: const Color(0xff1b2a34),
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: const Color(0xff2d424e)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.end,
				mainAxisAlignment: MainAxisAlignment.end,
				children: [
					Text(
						expression.isEmpty ? 'Ready when you are' : expression.replaceAll('*', ' × ').replaceAll('/', ' ÷ '),
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
						textAlign: TextAlign.right,
						style: const TextStyle(color: Color(0xffa9bbc4), fontSize: 20),
					),
					const SizedBox(height: 8),
					Text(
						error.isNotEmpty ? error : result.isEmpty ? '0' : '= $result',
						maxLines: 1,
						overflow: TextOverflow.ellipsis,
						style: TextStyle(
							color: error.isNotEmpty ? const Color(0xffff8f80) : Colors.white,
							fontSize: 38,
							fontWeight: FontWeight.w700,
						),
					),
				],
			),
		);
	}
}

class _CalculatorButton extends StatelessWidget {
	const _CalculatorButton({
		required this.label,
		required this.onPressed,
		required this.isAccent,
		required this.isOperator,
	});

	final String label;
	final VoidCallback onPressed;
	final bool isAccent;
	final bool isOperator;

	@override
	Widget build(BuildContext context) {
		return FilledButton(
			onPressed: onPressed,
			style: FilledButton.styleFrom(
				backgroundColor: isAccent
						? const Color(0xffef8354)
						: isOperator
								? const Color(0xff29404b)
								: const Color(0xff1b2a34),
				foregroundColor: isAccent ? const Color(0xff101820) : Colors.white,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
				textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
			),
			child: Text(label),
		);
	}
}
