CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsAssetByItemMasterAndCapes]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@ReferenceId bigint = '0',
@IsSubWorkOrder bit = false
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	
		DECLARE @ItemMasterId BIGINT;	
		DECLARE @WorkScopeId BIGINT;

		if(@IsSubWorkOrder = 1)
		BEGIN
			SELECT @ItemMasterId = WPN.ItemMasterId, @WorkScopeId = WPN.SubWorkOrderScopeId  FROM dbo.SubWorkOrderPartNumber WPN WITH(NOLOCK)
			WHERE WPN.SubWOPartNoId = @ReferenceId
		END
		ELSE
		BEGIN
			SELECT @ItemMasterId = WPN.ItemMasterId, @WorkScopeId = WPN.WorkOrderScopeId  FROM dbo.WorkOrderPartNumber WPN WITH(NOLOCK)
				JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WPN.ID = WOWF.WorkOrderPartNoId
			WHERE WOWF.WorkFlowWorkOrderId = @ReferenceId
		END

		PRINT @ItemMasterId;

		IF(@Count = '0') 
		   BEGIN
		   SET @Count='20';	
		END	
		IF(@IsActive = 1)
			BEGIN		
					SELECT DISTINCT TOP 20 
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						TC.TangibleClassName AS AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN [dbo].[AssetCapes] ac WITH(NOLOCK) ON a.AssetRecordId = ac.AssetRecordId
						JOIN [dbo].[AssetAttributeType] aat WITH(NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
						JOIN dbo.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND ac.ItemMasterId = @ItemMasterId AND (ac.IsActive=1 AND ISNULL(ac.IsDeleted,0) = 0 AND a.IsActive=1 AND ISNULL(a.IsDeleted,0) = 0 AND (Upper(TC.StatusCode) = 'EQUIPMENT' OR Upper(TC.StatusCode) = 'TOOLS' OR Upper(TC.StatusCode) = 'MACHINERY')
						AND (a.Name LIKE @StartWith + '%'))
			   UNION     
					SELECT DISTINCT  
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						TC.TangibleClassName AS AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN [dbo].[AssetCapes] ac WITH(NOLOCK) ON a.AssetRecordId = ac.AssetRecordId
						JOIN [dbo].[AssetAttributeType] aat WITH(NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
						JOIN dbo.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND a.AssetRecordId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 20 
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						TC.TangibleClassName AS AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a  WITH(NOLOCK)
						JOIN [dbo].[AssetCapes] ac WITH(NOLOCK) ON a.AssetRecordId = ac.AssetRecordId
						JOIN [dbo].[AssetAttributeType] aat WITH(NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
						JOIN dbo.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND ac.ItemMasterId = @ItemMasterId AND (ac.IsActive=1 AND ISNULL(ac.IsDeleted,0) = 0 AND a.IsActive=1 AND ISNULL(a.IsDeleted,0) = 0 AND (Upper(TC.StatusCode) = 'EQUIPMENT' OR Upper(TC.StatusCode) = 'TOOLS' OR Upper(TC.StatusCode) = 'MACHINERY')
						AND (a.Name LIKE '%' + @StartWith + '%'))
				UNION 
				SELECT DISTINCT  
						a.AssetRecordId AS Value, 
						a.Name AS Label,		
						a.AssetRecordId,
						a.AssetId, 
						a.Name, 
						a.Description, 
						TC.TangibleClassName AS AssetAttributeTypeName,
						a.TangibleClassId
					FROM dbo.Asset a WITH(NOLOCK)
						JOIN [dbo].[AssetCapes] ac WITH(NOLOCK) ON a.AssetRecordId = ac.AssetRecordId
						JOIN [dbo].[AssetAttributeType] aat WITH(NOLOCK) ON a.AssetAttributeTypeId = aat.AssetAttributeTypeId
						JOIN dbo.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = aat.TangibleClassId
					WHERE a.MasterCompanyId = @MasterCompanyId AND a.AssetRecordId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
				ORDER BY Label	
			END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsAssetByItemMasterAndCapes'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@ReferenceId, '') as varchar(100))		
			   + '@Parameter6 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END