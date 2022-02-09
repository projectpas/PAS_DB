

/*************************************************************           
 ** File:   [GetCustomerList]           
 ** Author:   Ameet Prajapati
 ** Description: Get Search Data for Customer List    
 ** Purpose:         
 ** Date:   14-Dec-2020        
          
 ** PARAMETERS: @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/14/2020   Hemant Saliya Created
	2    12/17/2020   Updated Like for General Filter
     
 EXECUTE [GetCustomerList] 1, 10, null, -1, 1, '', 'uday', 'CUS-00','','HYD'
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetCustomerList]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@Name varchar(50)=null,
	@CutomerCode varchar(50)=null,
	@Email varchar(50)=null,
	@City varchar(50)=null,
    @StateOrProvince varchar(50)=null,
    @AccountType varchar(50)=null,
    @CustomerType varchar(50)=null,
    @CustomerClassification varchar(200)=null,
    @Contact varchar(50)=null,
    @SalesPersonPrimary varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId bigint = NULL

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	

		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END				
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END
		IF @StatusID=0
		BEGIN 
			SET @IsActive=0
		END 
		ELSE IF @StatusID=1
		BEGIN 
			SET @IsActive=1
		END 
		ELSE IF @StatusID=2
		BEGIN 
			SET @IsActive=NULL
		END
		
		   ;WITH Result AS(
			SELECT	
					C.CustomerId, 
					C.[Name],
					C.CustomerCode,
					C.Email,
					CT.CustomerTypeName AS AccountType,
					STUFF((SELECT ', ' + CC.Description
							FROM dbo.ClassificationMapping cm WITH (NOLOCK)
							INNER JOIN dbo.CustomerClassification CC WITH (NOLOCK) ON CC.CustomerClassificationId=CM.ClasificationId
							WHERE cm.ReferenceId=C.CustomerId
							FOR XML PATH('')), 1, 1, '') 'CustomerClassification',
					A.City,
					a.StateOrProvince,
					(ISNULL(Contact.FirstName,'')+' '+ISNULL(Contact.LastName,'')) AS 'Contact',
					(ISNULL(E.FirstName,'')+' '+ISNULL(E.LastName,'')) AS 'SalesPersonPrimary',
					C.IsActive,
					C.IsDeleted,
					C.CreatedDate,
					C.CreatedBy,
					C.UpdatedDate,
					C.UpdatedBy,
					CA.[Description] AS CustomerType,
					C.IsTrackScoreCard
					FROM dbo.Customer C WITH (NOLOCK)
					INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
					INNER JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId=CA.CustomerAffiliationId
					LEFT JOIN  dbo.CustomerSales CS  WITH (NOLOCK) ON C.CustomerId=CS.CustomerId
					LEFT JOIN  dbo.Employee E  WITH (NOLOCK) ON CS.PrimarySalesPersonId=e.EmployeeId
					LEFT JOIN  dbo.Address a  WITH (NOLOCK) ON C.AddressId=a.AddressId
					LEFT JOIN  dbo.CustomerContact CC  WITH (NOLOCK) ON CC.CustomerId=C.CustomerId AND CC.IsDefaultContact=1
					LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CC.ContactId=Contact.ContactId
					Where ((C.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR C.IsActive=@IsActive))
					AND C.MasterCompanyId=@MasterCompanyId	
			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (
			(@GlobalFilter <>'' AND ((Name LIKE '%' +@GlobalFilter+'%' ) OR (CustomerCode LIKE '%' +@GlobalFilter+'%') OR
					(Email LIKE '%' +@GlobalFilter+'%') OR
					(City LIKE '%' +@GlobalFilter+'%') OR
					(StateOrProvince LIKE '%' +@GlobalFilter+'%') OR
					(AccountType LIKE '%' +@GlobalFilter+'%') OR
					(CustomerType LIKE '%' +@GlobalFilter+'%') OR
					(CustomerClassification LIKE '%' +@GlobalFilter+'%') OR
					(Contact LIKE '%' +@GlobalFilter+'%') OR
					(SalesPersonPrimary LIKE '%'+@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') 
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR Name LIKE '%' + @Name+'%') AND 
					(ISNULL(@CutomerCode,'') ='' OR CustomerCode LIKE '%' + @CutomerCode+'%') AND
					(ISNULL(@Email,'') ='' OR Email LIKE '%' + @Email+'%') AND
					(ISNULL(@City,'') ='' OR City LIKE '%' + @City+'%') AND
					(ISNULL(@StateOrProvince,'') ='' OR StateOrProvince LIKE '%' + @StateOrProvince+'%') AND
					(ISNULL(@AccountType,'') ='' OR AccountType LIKE '%' + @AccountType+'%') AND
					(ISNULL(@CustomerType,'') ='' OR CustomerType LIKE '%' + @CustomerType+'%') AND
					(ISNULL(@CustomerClassification,'') ='' OR CustomerClassification LIKE '%' + @CustomerClassification+'%') AND
					(ISNULL(@Contact,'') ='' OR Contact LIKE '%' + @Contact+'%') AND
					(ISNULL(@SalesPersonPrimary,'') ='' OR SalesPersonPrimary LIKE '%' + @SalesPersonPrimary+'%') and
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))
					)

			Select @Count = COUNT(CustomerId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,

			CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
            CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CutomerCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@Email , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@City , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@StateOrProvince, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@AccountType, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CustomerType, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@CustomerClassification, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@Contact , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@SalesPersonPrimary , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  			                                           
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