import java.util.Comparator;
import java.lang.Comparable;

public class JavaNaturalComparator<T extends Comparable<? super T>> implements Comparator<T> {
  @Override
  public int compare(T a, T b) {
    return a.compareTo(b);
  }
}
