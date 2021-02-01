double percentPosition(double value,{double min=0.0, double max=1.0}) {
    if (min >= max) return 0.0;

    if (value < min) return 0.0;

    if (value > max) return 1.0;

    double percent = ((value - min) / (max - min));

    return (double.parse(percent.toStringAsFixed(5)));
  }