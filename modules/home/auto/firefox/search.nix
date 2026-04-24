{ ... }:
{
  default = "ddg";
  engines = {
    # TODO: Add custom search
    # "Awesome Lists" = {
    #   urls = [ { template = "https://github.com/search?q=awesome+{searchTerms}&type=repositories"; } ];
    #
    #   definedAliases = [
    #     "@awesome"
    #   ];
    # };
    "wikipedia".metaData.hidden = true;
    "google".metaData.hidden = true;
    "amazondotcom-us".metaData.hidden = true;
    "bing".metaData.hidden = true;
    "ebay".metaData.hidden = true;
  };
}
