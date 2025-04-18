/*************************************************************           
 ** File:   [USP_GetVendorProformaInvoiceList]
 ** Author:   RAJESH GAMI
 ** Description: This stored procedure is used to Get Vendor Proforma Invoice List
 ** Purpose:         
 ** Date:    12/04/2024
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    04/Dec/2024		RAJESH GAMI				CREATED
	2    27/Dec/2024		RAJESH GAMI				Get the SUM of Amount when it's multiple
	3    10/04/2025	        Ekta Chandegra	        Convert date using dbo.ConvertUTCtoLocal

exec USP_GetVendorProformaInvoiceList 
@PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@HeaderStatusId=1,@ViewType=N'pnview',@VendorName=NULL,@VendorCode=NULL,
@InvoiceStatus=NULL,@PaymentTerms=NULL,@CreatedBy=NULL,@CreatedDate='2023-09-13 11:31:09.640',@UpdatedBy=NULL,@UpdatedDate='2023-09-13 11:31:09.640',@IsDeleted=0,@MasterCompanyId=1

************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetVendorProformaInvoiceList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@HeaderStatusId int = NULL,
@ViewType varchar(50) = null,
@VendorName varchar(50) = NULL,
@VendorCode varchar(50) = NULL,
@InvoiceStatus varchar(50) = NULL,
@PaymentTerms varchar(100) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@Amount  varchar(100) = NULL,
@GLAccount varchar(100) = NULL,
@InvoiceNum  varchar(100) = NULL,
@VendorProformaInvoiceNo varchar(100) = NULL,
@ReferenceNumber varchar(100) = NULL,
@EmployeeId BIGINT
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;

		DECLARE @AllStatusId INT = 8;
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
		
		IF (@HeaderStatusId = @AllStatusId OR @HeaderStatusId = 0)      
		BEGIN      
			SET @HeaderStatusId = NULL         
		END  

		IF(@ViewType = 'invoiceView')
		BEGIN
			;WITH Result AS(
				SELECT DISTINCT
						VPI.VendorProformaInvoiceId,
						VPI.VendorId,
						VPI.VendorName,
						VPI.VendorCode,
						VPI.PaymentTermsId,
						VPI.StatusId,
						VPI.ManagementStructureId,
						VPIS.Description AS [InvoiceStatus],
						CT.Name AS [PaymentTerms],
						ISNULL(VPI.IsActive,0) IsActive,
						ISNULL(VPI.IsDeleted,1) IsDeleted,
						(Cast(DBO.ConvertUTCtoLocal(VPI.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
						(Cast(DBO.ConvertUTCtoLocal(VPI.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate,
						VPI.CreatedBy CreatedBy,
						VPI.UpdatedBy UpdatedBy,
						VPI.MasterCompanyId,
						VPI.PaymentMethodId,
						VPI.VendorProformaInvoiceNo,
						(CASE WHEN COUNT(VPIP.VendorProformaInvoicePartDetailsId) > 1 Then CAST(SUM(VPIP.ExtendedPrice)AS VARCHAR) Else CAST(MAX(VPIP.ExtendedPrice) AS VARCHAR) End) as 'Amount',
						(CASE WHEN COUNT(VPIP.GlAccountId) > 1 Then 'Multiple' ELse MAX(GL.AccountCode) + '-' + MAX(GL.AccountName)   End) as 'GLAccount',
						VPI.InvoiceNumber as 'InvoiceNum'
				FROM [dbo].[VendorProformaInvoiceHeader] VPI WITH (NOLOCK)
				INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] VPIS WITH (NOLOCK) ON VPIS.VendorProformaInvoiceHeaderStatusId = VPI.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = VPI.PaymentTermsId
				LEFT JOIN [dbo].[VendorProformaInvoicePartDetails] VPIP WITH (NOLOCK) ON VPIP.VendorProformaInvoiceId = VPI.VendorProformaInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON VPIP.GlAccountId = GL.GlAccountId

				WHERE ((VPI.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR VPI.IsActive=@IsActive)) AND (@HeaderStatusId IS NULL OR VPI.StatusId = @HeaderStatusId)	     
					AND VPI.MasterCompanyId=@MasterCompanyId	
				GROUP BY VPI.VendorProformaInvoiceId,
					VPI.VendorId,
					VPI.VendorName,
					VPI.VendorCode,
					VPI.PaymentTermsId,
					VPI.StatusId,
					VPI.ManagementStructureId,
					VPIS.Description,
					CT.Name,
					VPI.IsActive,
					VPI.IsDeleted,
					VPI.CreatedDate,
					VPI.UpdatedDate,
					VPI.CreatedBy,
					VPI.UpdatedBy,
					VPI.MasterCompanyId,	
					VPI.PaymentMethodId,
					VPI.VendorProformaInvoiceNo,
					VPI.InvoiceNumber
			), ResultCount AS(SELECT COUNT(VendorProformaInvoiceId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(InvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(VendorProformaInvoiceNo LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@InvoiceStatus,'') ='' OR InvoiceStatus LIKE '%' + @InvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@VendorProformaInvoiceNo,'') ='' OR VendorProformaInvoiceNo LIKE '%' + @VendorProformaInvoiceNo + '%') AND		
					(ISNULL(@ReferenceNumber,'') ='' OR VendorProformaInvoiceNo LIKE '%' + @ReferenceNumber + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(CreatedDate,@CurrntEmpTimeZoneDesc) AS Date))=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(UpdatedDate,@CurrntEmpTimeZoneDesc) AS date))=CAST(@UpdatedDate AS date)))
					)

			SELECT @Count = COUNT(VendorProformaInvoiceId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceStatus')  THEN InvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceStatus')  THEN InvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;WITH Result AS(
				SELECT DISTINCT
						VPI.VendorProformaInvoiceId,
						VPI.VendorId,
						VPI.VendorName,
						VPI.VendorCode,
						VPI.PaymentTermsId,
						VPI.StatusId,
						VPI.ManagementStructureId,
						VPIS.Description AS [InvoiceStatus],
						CT.Name AS [PaymentTerms],
						ISNULL(VPI.IsActive,0) IsActive,
						ISNULL(VPI.IsDeleted,1) IsDeleted,
						VPI.CreatedDate,
						VPI.UpdatedDate,
						Upper(VPI.CreatedBy) CreatedBy,
						Upper(VPI.UpdatedBy) UpdatedBy,
						VPI.MasterCompanyId,
						VPI.PaymentMethodId,
						VPI.VendorProformaInvoiceNo,
						VPIP.ExtendedPrice AS Amount,
						GL.AccountCode  + '-' + GL.AccountName   as 'GLAccount',
						VPI.InvoiceNumber as 'InvoiceNum'
				FROM [dbo].[VendorProformaInvoiceHeader] VPI WITH (NOLOCK)
				INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] VPIS WITH (NOLOCK) ON VPIS.VendorProformaInvoiceHeaderStatusId = VPI.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = VPI.PaymentTermsId
				LEFT JOIN [dbo].[VendorProformaInvoicePartDetails] VPIP WITH (NOLOCK) ON VPIP.VendorProformaInvoiceId = VPI.VendorProformaInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON VPIP.GlAccountId = GL.GlAccountId

		 	  WHERE ((VPI.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR VPI.IsActive=@IsActive)) AND (@HeaderStatusId IS NULL OR VPI.StatusId = @HeaderStatusId)		     
					AND VPI.MasterCompanyId=@MasterCompanyId	
			),ResultData AS( Select VendorProformaInvoiceId, VendorId, VendorName, VendorCode, PaymentTermsId, StatusId, ManagementStructureId, InvoiceStatus, PaymentTerms,
						IsActive, IsDeleted, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, MasterCompanyId, PaymentMethodId, VendorProformaInvoiceNo, Amount, GLAccount, InvoiceNum
						FROM Result
			WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(InvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(VendorProformaInvoiceNo LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@InvoiceStatus,'') ='' OR InvoiceStatus LIKE '%' + @InvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@VendorProformaInvoiceNo,'') ='' OR VendorProformaInvoiceNo LIKE '%' + @VendorProformaInvoiceNo + '%') AND
					(ISNULL(@ReferenceNumber,'') ='' OR VendorProformaInvoiceNo LIKE '%' + @ReferenceNumber + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)
			), ResultCount AS (Select COUNT(VendorProformaInvoiceId) AS NumberOfItems FROM ResultData)

			SELECT	VendorProformaInvoiceId, VendorId, VendorName, VendorCode, PaymentTermsId, StatusId, ManagementStructureId, InvoiceStatus, PaymentTerms,
				IsActive, IsDeleted, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, MasterCompanyId, PaymentMethodId,
				VendorProformaInvoiceNo, Amount, GLAccount, InvoiceNum, NumberOfItems FROM ResultData,ResultCount
			ORDER BY		
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceStatus')  THEN InvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceStatus')  THEN InvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END DESC,
			--CASE WHEN (@SortOrder=1  AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END ASC,
			--CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorProformaInvoiceNo')  THEN VendorProformaInvoiceNo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
		END	

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetVendorProformaInvoiceList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@ViewType, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@InvoiceStatus , '') AS varchar(100))	
			   + '@Parameter11 = ''' + CAST(ISNULL(@PaymentTerms , '') AS varchar(100))		  
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))	                                           
			  + '@Parameter18 = ''' + CAST(ISNULL(@Amount, '') AS varchar(100))	                                           
			  + '@Parameter19 = ''' + CAST(ISNULL(@GLAccount, '') AS varchar(100))	                                           
			  + '@Parameter20 = ''' + CAST(ISNULL(@VendorProformaInvoiceNo, '') AS varchar(100))	                                           
			  + '@Parameter21 = ''' + CAST(ISNULL(@InvoiceNum, '') AS varchar(100))	                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END