import java.nio.file.*;
import org.apache.maven.artifact.versioning.*;
class CheckRanges {
 public static void main(String[] args) throws Exception {
  int n=0;
  for(String s:Files.readAllLines(Paths.get(args[0]))) {
   String[] a=s.split("\\t");
   if(a[2].equals("*")||a[2].isEmpty()) continue;
   VersionRange range=VersionRange.createFromVersionSpec(a[2]);
   boolean contains=range.containsVersion(new DefaultArtifactVersion(a[1]));
   // FML 4.0.45 VersionSupportMatrix, Minecraft 1.21.1 compatibility aliases.
   if (!contains && a[0].endsWith("->minecraft")) contains=range.containsVersion(new DefaultArtifactVersion("1.21"));
   if (!contains && a[0].endsWith("->neoforge")) contains=range.containsVersion(new DefaultArtifactVersion("21.0.166"));
   if(a[3].equals("incompatible") ? contains : !contains) throw new RuntimeException(s);
   n++;
  }
  System.out.println("PASS: "+n+" Maven version interval checks");
 }
}
