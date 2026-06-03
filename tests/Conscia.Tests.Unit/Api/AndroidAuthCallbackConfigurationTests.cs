using System.Xml.Linq;

namespace Conscia.Tests.Unit.Api;

public class AndroidAuthCallbackConfigurationTests
{
    [Fact]
    public void FlutterWebAuthCallbackActivity_UsesEmptyTaskAffinity()
    {
        var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
        var manifestPath = Path.Combine(repoRoot, "app", "android", "app", "src", "main", "AndroidManifest.xml");
        XNamespace android = "http://schemas.android.com/apk/res/android";

        var manifest = XDocument.Load(manifestPath);
        var callbackActivity = manifest
            .Descendants("activity")
            .Single(activity =>
                (string?)activity.Attribute(android + "name") ==
                "com.linusu.flutter_web_auth_2.CallbackActivity");

        Assert.Equal(string.Empty, (string?)callbackActivity.Attribute(android + "taskAffinity"));
    }
}
