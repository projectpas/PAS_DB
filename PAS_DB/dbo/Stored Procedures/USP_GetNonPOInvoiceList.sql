/*************************************************************           
 ** File:   [USP_GetNonPOInvoiceList]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Get NOnpoinvoice list
 ** Purpose:         
 ** Date:    09/13/2023
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    09/13/2023		Devendra Shekh					Created
    2    09/14/2023		Devendra Shekh					added paymentmethodId
    3    10/03/2023		Devendra Shekh					changes for multiple part

--EXEC [USP_GetNonPOInvoiceList] 3577,3047

exec USP_GetNonPOInvoiceList 
@PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@ViewType=N'pnview',@VendorName=NULL,@VendorCode=NULL,
@NonPoInvoiceStatus=NULL,@PaymentTerms=NULL,@CreatedBy=NULL,@CreatedDate='2023-09-13 11:31:09.640',@UpdatedBy=NULL,@UpdatedDate='2023-09-13 11:31:09.640',@IsDeleted=0,@MasterCompanyId=1

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetNonPOInvoiceList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@ViewType varchar(50) = null,
@VendorName varchar(50) = NULL,
@VendorCode varchar(50) = NULL,
@NonPoInvoiceStatus varchar(50) = NULL,
@PaymentTerms varchar(100) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@Amount  varchar(100) = NULL,
@GLAccount varchar(100) = NULL,
@NPONumber varchar(100) = NULL,
@InvoiceNum  varchar(100) = NULL
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

		IF(@ViewType = 'npoview')
		BEGIN
			;WITH Result AS(
				SELECT DISTINCT
						NPH.NonPOInvoiceId,
						NPH.VendorId,
						NPH.VendorName,
						NPH.VendorCode,
						NPH.PaymentTermsId,
						NPH.StatusId,
						NPH.ManagementStructureId,
						NPHS.Description AS [NonPoInvoiceStatus],
						CT.Name AS [PaymentTerms],
						NPH.IsActive,
						NPH.IsDeleted,
						NPH.CreatedDate,
						NPH.UpdatedDate,
						Upper(NPH.CreatedBy) CreatedBy,
						Upper(NPH.UpdatedBy) UpdatedBy,
						NPH.MasterCompanyId,
						NPH.PaymentMethodId,
						NPH.NPONumber,
						(CASE WHEN COUNT(NPD.NonPOInvoicePartDetailsId) > 1 Then 'Multiple' ELse CAST(MAX(NPD.Amount) AS VARCHAR) End) as 'Amount',
						(CASE WHEN COUNT(NPD.GlAccountId) > 1 Then 'Multiple' ELse MAX(GL.AccountName) + '-' + MAX(GL.AccountCode)  End) as 'GLAccount',
						(CASE WHEN COUNT(NPD.InvoiceNum) > 1 Then 'Multiple' ELse MAX(NPD.InvoiceNum) End) as 'InvoiceNum'
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
				LEFT JOIN [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK) ON NPD.NonPOInvoiceId = NPH.NonPOInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON NPD.GlAccountId = GL.GlAccountId

				WHERE ((NPH.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR NPH.IsActive=@IsActive))			     
					AND NPH.MasterCompanyId=@MasterCompanyId	
				GROUP BY NPH.NonPOInvoiceId,
					NPH.VendorId,
					NPH.VendorName,
					NPH.VendorCode,
					NPH.PaymentTermsId,
					NPH.StatusId,
					NPH.ManagementStructureId,
					NPHS.Description,
					CT.Name,
					NPH.IsActive,
					NPH.IsDeleted,
					NPH.CreatedDate,
					NPH.UpdatedDate,
					NPH.CreatedBy,
					NPH.UpdatedBy,
					NPH.MasterCompanyId,	
					NPH.PaymentMethodId,
					NPH.NPONumber
			), ResultCount AS(SELECT COUNT(NonPOInvoiceId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(NonPoInvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(NPONumber LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@NonPoInvoiceStatus,'') ='' OR NonPoInvoiceStatus LIKE '%' + @NonPoInvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@NPONumber,'') ='' OR NPONumber LIKE '%' + @NPONumber + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)

			SELECT @Count = COUNT(NonPOInvoiceId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NPONumber')  THEN NPONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NPONumber')  THEN NPONumber END DESC,
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
						NPH.NonPOInvoiceId,
						NPH.VendorId,
						NPH.VendorName,
						NPH.VendorCode,
						NPH.PaymentTermsId,
						NPH.StatusId,
						NPH.ManagementStructureId,
						NPHS.Description AS [NonPoInvoiceStatus],
						CT.Name AS [PaymentTerms],
						NPH.IsActive,
						NPH.IsDeleted,
						NPH.CreatedDate,
						NPH.UpdatedDate,
						Upper(NPH.CreatedBy) CreatedBy,
						Upper(NPH.UpdatedBy) UpdatedBy,
						NPH.MasterCompanyId,
						NPH.PaymentMethodId,
						NPH.NPONumber,
						NPD.Amount,
						GL.AccountName + '-' + GL.AccountCode  as 'GLAccount',
						NPD.InvoiceNum as 'InvoiceNum'
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
				LEFT JOIN [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK) ON NPD.NonPOInvoiceId = NPH.NonPOInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON NPD.GlAccountId = GL.GlAccountId

		 	  WHERE ((NPH.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR NPH.IsActive=@IsActive))			     
					AND NPH.MasterCompanyId=@MasterCompanyId	
			),ResultData AS( Select NonPOInvoiceId, VendorId, VendorName, VendorCode, PaymentTermsId, StatusId, ManagementStructureId, NonPoInvoiceStatus, PaymentTerms,
						IsActive, IsDeleted, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, MasterCompanyId, PaymentMethodId, NPONumber, Amount, GLAccount, InvoiceNum
						FROM Result
			WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(NonPoInvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(NPONumber LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@NonPoInvoiceStatus,'') ='' OR NonPoInvoiceStatus LIKE '%' + @NonPoInvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@NPONumber,'') ='' OR NPONumber LIKE '%' + @NPONumber + '%') AND							
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)
			), ResultCount AS (Select COUNT(NonPOInvoiceId) AS NumberOfItems FROM ResultData)

			SELECT	NonPOInvoiceId, VendorId, VendorName, VendorCode, PaymentTermsId, StatusId, ManagementStructureId, NonPoInvoiceStatus, PaymentTerms,
				IsActive, IsDeleted, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, MasterCompanyId, PaymentMethodId,
				NPONumber, Amount, GLAccount, InvoiceNum, NumberOfItems FROM ResultData,ResultCount
			ORDER BY		
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NPONumber')  THEN NPONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NPONumber')  THEN NPONumber END DESC,
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
			,@AdhocComments VARCHAR(150) = 'USP_GetNonPOInvoiceList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@ViewType, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@NonPoInvoiceStatus , '') AS varchar(100))	
			   + '@Parameter11 = ''' + CAST(ISNULL(@PaymentTerms , '') AS varchar(100))		  
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))	                                           
			  + '@Parameter18 = ''' + CAST(ISNULL(@Amount, '') AS varchar(100))	                                           
			  + '@Parameter19 = ''' + CAST(ISNULL(@GLAccount, '') AS varchar(100))	                                           
			  + '@Parameter20 = ''' + CAST(ISNULL(@NPONumber, '') AS varchar(100))	                                           
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