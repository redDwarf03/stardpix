import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardpix/ui/views/layer/bloc/provider.dart';

class IconTimer extends ConsumerStatefulWidget {
  const IconTimer({
    super.key,
  });

  @override
  ConsumerState<IconTimer> createState() => IconTimerState();
}

class IconTimerState extends ConsumerState<IconTimer> {
  bool? paint;
  final CountDownController _controller = CountDownController();

  @override
  void initState() {
    _controller.start();
    paint = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final layer = ref.watch(LayerFormProvider.layerForm);
    if (layer.timeLockInSeconds == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Row(
        children: [
          CircularCountDownTimer(
            duration: layer.timeLockInSeconds,
            controller: _controller,
            width: 50,
            height: 45,
            ringColor: Colors.black,
            fillColor: Colors.orange[200]!,
            backgroundColor: paint != null && paint == true
                ? Colors.green[100]
                : Colors.orange[200],
            strokeWidth: 3,
            strokeCap: StrokeCap.square,
            textStyle: TextStyle(
              fontSize: 10,
              color: paint != null && paint == true
                  ? Colors.green[900]
                  : Colors.orange[900],
              fontWeight: FontWeight.bold,
            ),
            textFormat: CountdownTextFormat.MM_SS,
            isReverse: true,
            isReverseAnimation: true,
            onStart: () {},
            onComplete: () {
              setState(() {
                paint = true;
              });
              ref
                  .read(LayerFormProvider.layerForm.notifier)
                  .setTimeLockInSeconds(0);
            },
            onChange: (String timeStamp) {},
            timeFormatterFunction: (defaultFormatterFunction, duration) {
              if (duration.inMilliseconds == 0) {
                return 'Paint!';
              } else {
                return Function.apply(defaultFormatterFunction, [duration]);
              }
            },
          ),
        ],
      ),
    );
  }
}
