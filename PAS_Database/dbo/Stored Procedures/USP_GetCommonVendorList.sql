/*************************************************************               
 ** File:   [USP_GetCommonVendorList]               
 ** Author:   Devendra Shekh      
 ** Description: Get Common Vendor List Data
 ** Purpose:             
 ** Date:   22th April 2024     
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------     
 **	1	22-04-2022   Devendra Shekh			created    
 
exec USP_GetCommonVendorList @PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@VendorName=NULL,
@VendorCode=NULL,@VendorEmail=NULL,@City=NULL,@StateOrProvince=NULL,@ClassificationName=NULL,@VendorPhoneContact=NULL,@Description=NULL,
@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@MasterCompanyId=1,@SelectedVendorId=1291
**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_GetCommonVendorList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@VendorName varchar(50) = NULL,
@VendorCode varchar(50) = NULL,
@VendorEmail varchar(50) = NULL,
@City varchar(50) = NULL,
@StateOrProvince varchar(50) = NULL,
@ClassificationName varchar(50) = NULL,
@VendorPhoneContact varchar(50) = NULL,
@Description varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@SelectedVendorId bigint = NULL,
@IsInitialCall bit = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

		IF OBJECT_ID(N'tempdb..#TEMPVendorListData') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPVendorListData
		END

		CREATE TABLE #TEMPVendorListData(        
			ID BIGINT IDENTITY(1,1),        
			VendorId BIGINT NULL,
			VendorName VARCHAR(100) NULL,
			VendorCode VARCHAR(100) NULL,
			Description NVARCHAR(512) NULL,
			VendorEmail VARCHAR(200) NULL,
			City VARCHAR(50) NULL,
			StateOrProvince VARCHAR(50) NULL,
			VendorPhoneContact VARCHAR(130) NULL,
			CreatedDate DATETIME2 NULL,
			CreatedBy VARCHAR(256) NULL,
			UpdatedDate DATETIME2 NULL,
			UpdatedBy VARCHAR(256) NULL,
			IsDeleted BIT NULL,
			IsActive BIT NULL,
			ClassificationName VARCHAR(256) NULL,
			MasterCompanyId BIGINT NULL,
		) 
				
			INSERT INTO #TEMPVendorListData([VendorId], [VendorName], [VendorCode], [Description], [VendorEmail], [City], [StateOrProvince], [VendorPhoneContact]
						,[CreatedDate], [CreatedBy], [UpdatedDate], [UpdatedBy], [IsDeleted], [IsActive], [ClassificationName], [MasterCompanyId])
			SELECT DISTINCT V.VendorId,
							V.VendorName,
							V.VendorCode,                   
							VT.[Description],  
							V.VendorEmail,               
							(ISNULL(AD.City,'')) 'City',
							(ISNULL(AD.StateOrProvince, '')) 'StateOrProvince',
							(ISNULL(CON.FirstName, '') + ' ' + ISNULL(CON.LastName, '')) 'VendorPhoneContact',                   
							V.CreatedDate,
							V.CreatedBy,
							V.UpdatedDate,
							V.UpdatedBy,                   			                  
							V.IsDeleted,
							V.IsActive,
							ISNULL(A.ClassificationName, '') 'ClassificationName',
							V.MasterCompanyId
					FROM dbo.Vendor V  WITH (NOLOCK) INNER JOIN dbo.[Address] AD WITH (NOLOCK) ON V.AddressId=AD.AddressId
						 LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
						 LEFT JOIN dbo.VendorContact CC WITH (NOLOCK) ON V.VendorId = CC.VendorId AND CC.IsDefaultContact = 1
						 LEFT JOIN dbo.Contact CON WITH (NOLOCK) ON CC.ContactId = CON.ContactId 
						 OUTER APPLY(SELECT STUFF((SELECT ', ' + VC.ClassificationName
						 FROM dbo.ClassificationMapping CM  WITH (NOLOCK)
						 INNER JOIN dbo.VendorClassification VC WITH (NOLOCK) ON VC.VendorClassificationId = CM.ClasificationId
						 Where CM.ReferenceId = V.VendorId AND CM.ModuleId = 3
						 FOR XML PATH('')), 1, 1, '') ClassificationName) A
					WHERE ((V.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR V.IsActive = @IsActive)) AND V.MasterCompanyId=@MasterCompanyId AND V.VendorId = @SelectedVendorId
			
			INSERT INTO #TEMPVendorListData([VendorId], [VendorName], [VendorCode], [Description], [VendorEmail], [City], [StateOrProvince], [VendorPhoneContact]
							,[CreatedDate], [CreatedBy], [UpdatedDate], [UpdatedBy], [IsDeleted], [IsActive], [ClassificationName], [MasterCompanyId])
			SELECT DISTINCT V.VendorId,
							V.VendorName,
							V.VendorCode,                   
							VT.[Description],  
							V.VendorEmail,               
							(ISNULL(AD.City,'')) 'City',
							(ISNULL(AD.StateOrProvince, '')) 'StateOrProvince',
							(ISNULL(CON.FirstName, '') + ' ' + ISNULL(CON.LastName, '')) 'VendorPhoneContact',                   
							V.CreatedDate,
							V.CreatedBy,
							V.UpdatedDate,
							V.UpdatedBy,                   			                  
							V.IsDeleted,
							V.IsActive,
							ISNULL(A.ClassificationName, '') 'ClassificationName',
							V.MasterCompanyId
					FROM dbo.Vendor V  WITH (NOLOCK) INNER JOIN  dbo.[Address] AD WITH (NOLOCK) ON V.AddressId=AD.AddressId
						LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
						LEFT JOIN dbo.VendorContact CC WITH (NOLOCK) ON V.VendorId = CC.VendorId AND CC.IsDefaultContact = 1
						LEFT JOIN dbo.Contact CON WITH (NOLOCK) ON CC.ContactId = CON.ContactId 
						OUTER APPLY(SELECT STUFF((SELECT ', ' + VC.ClassificationName
						FROM dbo.ClassificationMapping CM  WITH (NOLOCK)
						INNER JOIN dbo.VendorClassification VC WITH (NOLOCK) ON VC.VendorClassificationId = CM.ClasificationId
						Where CM.ReferenceId = V.VendorId AND CM.ModuleId = 3
						FOR XML PATH('')), 1, 1, '') ClassificationName) A
					WHERE ((V.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR V.IsActive = @IsActive)) AND V.MasterCompanyId=@MasterCompanyId AND V.VendorId != @SelectedVendorId

			;WITH ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM #TEMPVendorListData)
			SELECT * INTO #TempResult FROM  #TEMPVendorListData
			WHERE ((@GlobalFilter <>'' AND ((VendorCode LIKE '%' +@GlobalFilter+'%') OR
			        (VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorEmail LIKE '%' +@GlobalFilter+'%') OR					
					([Description] LIKE '%' +@GlobalFilter+'%') OR						
					(City LIKE '%' +@GlobalFilter+'%') OR						
					(StateOrProvince LIKE '%' +@GlobalFilter+'%') OR
					(VendorPhoneContact LIKE '%' +@GlobalFilter+'%') OR						
					(ClassificationName LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode+'%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorEmail,'') ='' OR VendorEmail LIKE '%' + @VendorEmail + '%') AND
					(ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@City,'') ='' OR City LIKE '%' + @City + '%') AND
					(ISNULL(@StateOrProvince,'') ='' OR StateOrProvince LIKE '%' + @StateOrProvince + '%') AND
					(ISNULL(@VendorPhoneContact,'') ='' OR VendorPhoneContact LIKE '%' + @VendorPhoneContact + '%') AND
					(ISNULL(@ClassificationName,'') ='' OR ClassificationName LIKE '%' + @ClassificationName + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND													
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

		SELECT @Count = COUNT(VendorId) FROM #TempResult			

		SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN ISNULL(@SelectedVendorId, 0) > 0 AND ISNULL(@IsInitialCall, 0) = 1 THEN [ID] END ASC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorEmail')  THEN VendorEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorEmail')  THEN VendorEmail END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='ClassificationName')  THEN ClassificationName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClassificationName')  THEN ClassificationName END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY

		END TRY    
		BEGIN CATCH      
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetCommonVendorList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))			   
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorEmail , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@City , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@StateOrProvince, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@ClassificationName, '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@VendorPhoneContact, '') AS varchar(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@Description, '') AS varchar(100))
			   + '@Parameter15 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			   + '@Parameter16 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			   + '@Parameter17 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			   + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))			
			   + '@Parameter19 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			   + '@Parameter20 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			   ,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END