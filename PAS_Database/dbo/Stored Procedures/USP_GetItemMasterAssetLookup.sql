/*************************************************************
 ** File:   [USP_GetItemMasterAssetLookup]
 ** Author: Rajesh Gami
 ** Description: [PN-18406] Allow Asset in Item Master - Alternate Asset ID / Asset Parent dropdown:
 **              Item Master rows whose Item Type is Asset (IsAsset = 1), searched by PN, plus the ids
 **              already selected (@IdList) so edit mode always shows them.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    26/October/2026 RAJESH GAMI     Created [PN-18406]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetItemMasterAssetLookup]
	@MasterCompanyId     INT,
	@SearchText          VARCHAR(100) = NULL,
	@IdList              VARCHAR(MAX) = NULL,
	@ExcludeItemMasterId BIGINT = NULL,
	@Count               INT = 20
AS
BEGIN
	SET NOCOUNT ON;
	SET @SearchText = LTRIM(RTRIM(ISNULL(@SearchText,'')));
	SET @Count = CASE WHEN ISNULL(@Count,0) <= 0 THEN 20 ELSE @Count END;

	SELECT AssetLookup.[value], AssetLookup.[label]
	FROM (
		SELECT TopAssetItem.[value], TopAssetItem.[label]
		FROM (
		SELECT TOP (@Count) AssetItem.ItemMasterId AS [value], AssetItem.partnumber AS [label]
		FROM dbo.ItemMaster AssetItem WITH (NOLOCK)
		WHERE AssetItem.MasterCompanyId = @MasterCompanyId
		  AND ISNULL(AssetItem.IsAsset,0) = 1
		  AND ISNULL(AssetItem.IsDeleted,0) = 0
		  AND ISNULL(AssetItem.IsActive,1) = 1
		  AND AssetItem.ItemMasterId <> ISNULL(@ExcludeItemMasterId, 0)
		  AND (@SearchText = '' OR AssetItem.partnumber LIKE @SearchText + '%')
		ORDER BY AssetItem.partnumber
		) TopAssetItem

		UNION

		SELECT SelectedAssetItem.ItemMasterId AS [value], SelectedAssetItem.partnumber AS [label]
		FROM dbo.ItemMaster SelectedAssetItem WITH (NOLOCK)
		WHERE ISNULL(@IdList,'') <> ''
		  AND SelectedAssetItem.ItemMasterId IN (SELECT Item FROM dbo.SPLITSTRING(@IdList, ','))
	) AssetLookup
	ORDER BY AssetLookup.[label];
END
